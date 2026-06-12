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
    const { error: rpcError } = await supabase.rpc('create_ledger_entry', {
      p_user_id: user_id,
      p_amount: amount,
      p_reference: paymentIntent.id,
      p_type: 'deposit'
    })

    if (rpcError) {
      console.error('Error creating ledger entry:', rpcError)
      return new Response(JSON.stringify({ error: rpcError.message }), { status: 500 })
    }
      
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
