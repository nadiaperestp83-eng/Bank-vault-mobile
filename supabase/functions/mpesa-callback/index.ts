import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
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
      // 1. Fetch transaction details
      const { data: transaction, error: txError } = await supabase
        .from('transactions')
        .select('sender_id, amount')
        .eq('description', checkoutRequestID)
        .single()

      if (!txError && transaction) {
        // 2. Use create_ledger_entry RPC to atomically update balance and ledger
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
  } catch (error) {
    console.error('Error in mpesa-callback:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
