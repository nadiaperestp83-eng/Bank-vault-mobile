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

-- Trigger function to update wallet balance and create ledger entry
CREATE OR REPLACE FUNCTION handle_transaction_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_wallet_id UUID;
  v_new_balance DECIMAL(12, 2);
BEGIN
  -- Only fire when status changes to 'completed'
  IF (NEW.status = 'completed'::transaction_status AND (OLD.status IS NULL OR OLD.status != 'completed'::transaction_status)) THEN
    
    -- Get the user's wallet (Assumes 1 wallet per profile)
    SELECT id INTO v_wallet_id FROM wallets WHERE user_id = NEW.receiver_id LIMIT 1;

    IF v_wallet_id IS NOT NULL THEN
      -- 1. Atomically increment the balance
      UPDATE wallets
      SET balance = balance + NEW.amount,
          updated_at = now()
      WHERE id = v_wallet_id
      RETURNING balance INTO v_new_balance;

      -- 2. Create a ledger entry (Double-entry accounting)
      INSERT INTO ledger_entries (transaction_id, wallet_id, amount, entry_type)
      VALUES (NEW.id, v_wallet_id, NEW.amount, 'credit');

      -- 3. Update balance_after in the transaction record for audit trailing
      NEW.balance_after := v_new_balance;
    END IF;

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger (BEFORE UPDATE to allow modifying NEW.balance_after)
CREATE TRIGGER tr_on_transaction_completed
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  WHEN (NEW.status = 'completed'::transaction_status AND OLD.status != 'completed'::transaction_status)
  EXECUTE FUNCTION handle_transaction_completion();
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
    await supabase
      .from('transactions')
      .update({ status: 'completed' })
      .eq('description', checkoutRequestID)
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
    await supabase
      .from('transactions')
      .update({ status: 'completed' })
      .eq('description', paymentIntent.id)
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
