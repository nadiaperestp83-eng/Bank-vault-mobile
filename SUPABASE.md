# Supabase Configuration for Vault OS Deposit Flow

This document contains the backend logic (SQL Triggers and Edge Functions) required to complete the end-to-end deposit flow for M-Pesa and Stripe, aligned with your `transactions` table schema.

## 1. Database Schema & Triggers (Step 5: Atomic Ledger Update)

Execute the following SQL in the Supabase SQL Editor to handle completed transactions.

```sql
-- Double-entry accounting: Ledger Entries table
CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID REFERENCES transactions(id),
  wallet_id UUID REFERENCES wallets(id),
  amount DECIMAL(18, 2) NOT NULL,
  entry_type TEXT NOT NULL, -- 'credit' or 'debit'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Step 5: Atomic Ledger Update
-- Note: We use the create_ledger_entry RPC directly from webhooks for Stripe and M-Pesa
-- to ensure idempotency and atomic updates. No separate trigger is required for these flows.

-- Double-entry accounting: create_ledger_entry RPC
-- This RPC is used by Stripe webhooks and M-Pesa callbacks to atomically update balance and ledger.
CREATE OR REPLACE FUNCTION create_ledger_entry(
  p_user_id UUID,
  p_amount DECIMAL,
  p_reference TEXT, -- Stripe PaymentIntent ID or M-Pesa CheckoutID
  p_type TEXT
) RETURNS VOID AS $$
DECLARE
  v_wallet_id UUID;
  v_transaction_id UUID;
  v_new_balance DECIMAL(12, 2);
BEGIN
  -- 1. Idempotency Check: Check if transaction already exists with this reference and is completed
  SELECT id INTO v_transaction_id FROM transactions WHERE description = p_reference AND status = 'completed';
  IF FOUND THEN
    RETURN; -- Already processed
  END IF;

  -- 2. Get user's wallet
  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_user_id LIMIT 1;
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;

  -- 3. Balance Update: Atomically increment the balance
  UPDATE wallets
  SET balance = balance + p_amount,
      updated_at = now()
  WHERE id = v_wallet_id
  RETURNING balance INTO v_new_balance;

  -- 4. Transaction Log: Update existing pending transaction or create a new one
  UPDATE transactions
  SET status = 'completed',
      balance_after = v_new_balance
  WHERE description = p_reference
  RETURNING id INTO v_transaction_id;

  IF v_transaction_id IS NULL THEN
    -- Create a new transaction if one didn't exist (unlikely for Stripe, but possible for M-Pesa)
    INSERT INTO transactions (sender_id, receiver_id, amount, type, status, description, balance_after, method)
    VALUES (p_user_id, p_user_id, p_amount, p_type, 'completed', p_reference, v_new_balance, 'card')
    RETURNING id INTO v_transaction_id;
  END IF;

  -- 5. Ledger Entry: Insert immutable row (Double-entry accounting)
  INSERT INTO ledger_entries (transaction_id, wallet_id, amount, entry_type)
  VALUES (v_transaction_id, v_wallet_id, p_amount, 'credit');

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 2. M-Pesa Callback Edge Function (Step 4)

This logic should be implemented in your `mpesa-callback` Supabase Edge Function.

```typescript
// supabase/functions/mpesa-callback/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { Body } = await req.json()
  const stkCallback = Body.stkCallback
  const checkoutRequestID = stkCallback.CheckoutRequestID
  const resultCode = stkCallback.ResultCode

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  if (resultCode === 0) {
    // Success
    // Fetch transaction details
    const { data: transaction } = await supabase
      .from('transactions')
      .select('sender_id, amount')
      .eq('description', checkoutRequestID)
      .single()

    if (transaction) {
      // Use create_ledger_entry RPC to atomically update balance and ledger
      await supabase.rpc('create_ledger_entry', {
        p_user_id: transaction.sender_id,
        p_amount: transaction.amount,
        p_reference: checkoutRequestID,
        p_type: 'deposit'
      })
    }
  } else {
    // Failure
    await supabase
      .from('transactions')
      .update({ 
        status: 'failed',
        description: `M-Pesa Error Code: ${resultCode}` 
      })
      .eq('description', checkoutRequestID)
  }

  return new Response(JSON.stringify({ ResultCode: 0, ResultDesc: "Success" }), {
    headers: { "Content-Type": "application/json" },
  })
})
```

## 3. Stripe Webhook Listener (Step 4)

This logic should be implemented in your `stripe-webhook` Supabase Edge Function.

```typescript
// supabase/functions/stripe-webhook/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Stripe from 'https://esm.sh/stripe?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')
  const body = await req.text()
  
  let event
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature!,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object
    const user_id = paymentIntent.metadata.user_id
    const amount = paymentIntent.amount / 100

    // Use create_ledger_entry RPC to atomically update balance and ledger with idempotency
    await supabase.rpc('create_ledger_entry', {
      p_user_id: user_id,
      p_amount: amount,
      p_reference: paymentIntent.id,
      p_type: 'deposit'
    })
  } else if (event.type === 'payment_intent.payment_failed') {
    const paymentIntent = event.data.object
    await supabase
      .from('transactions')
      .update({ 
        status: 'failed',
        description: paymentIntent.last_payment_error?.message 
      })
      .eq('description', paymentIntent.id)
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  })
})
```

## 4. Stripe Create Intent Edge Function (Step 2)

This logic should be implemented in your `stripe-create-intent` Supabase Edge Function.

```typescript
// supabase/functions/stripe-create-intent/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Stripe from 'https://esm.sh/stripe?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    const { amount, currency, payment_method_types } = await req.json()
    
    // Get user ID from Auth header to secure the request
    const authHeader = req.headers.get('Authorization')!
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { 
        status: 401,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      })
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Cents
      currency: currency || 'usd',
      payment_method_types: payment_method_types || ['card'],
      metadata: { user_id: user.id },
    })

    return new Response(JSON.stringify({ 
      id: paymentIntent.id,
      clientSecret: paymentIntent.client_secret 
    }), {
      headers: { 
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 400,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }
})
```
