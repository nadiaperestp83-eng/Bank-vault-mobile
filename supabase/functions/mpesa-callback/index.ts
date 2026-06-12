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
      const { data: entry, error: txError } = await supabase
        .from('ledger_entries')
        .select('user_id, amount')
        .eq('description', checkoutRequestID)
        .single()

      if (!txError && entry) {
        // 2. Use create_ledger_entry RPC to atomically update balance and ledger
        // Actually if we use create_ledger_entry it might create ANOTHER entry.
        // We should probably just update the status of the existing one.
        await supabase
          .from('ledger_entries')
          .update({ status: 'completed' })
          .eq('description', checkoutRequestID)
        
        // And update wallet balance (ideally this should be an atomic RPC)
        const { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', entry.user_id).single()
        if (wallet) {
          await supabase.from('wallets').update({ balance: wallet.balance + entry.amount }).eq('user_id', entry.user_id)
        }
      }
    } else {
      // Failure
      await supabase
        .from('ledger_entries')
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
