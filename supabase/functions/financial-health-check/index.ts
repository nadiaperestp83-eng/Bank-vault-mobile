import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders })
    }

    // 1. Fetch recent transactions for analysis
    const { data: transactions } = await supabase
      .from('transactions')
      .select('amount, type, created_at')
      .eq('sender_id', user.id)
      .order('created_at', ascending: false)
      .limit(50)

    // 2. Simple analysis logic
    let totalSpent = 0
    let depositCount = 0
    let withdrawalCount = 0

    transactions?.forEach(tx => {
      if (tx.type === 'transfer' || tx.type === 'withdrawal') totalSpent += tx.amount
      if (tx.type === 'deposit') depositCount++
      if (tx.type === 'withdrawal') withdrawalCount++
    })

    const healthScore = Math.max(0, Math.min(100, 100 - (withdrawalCount * 5) + (depositCount * 2)))
    
    let insight = "Your financial health looks stable. Keep up the good work!"
    if (healthScore < 50) {
      insight = "You've had quite a few withdrawals recently. Consider reviewing your spending habits."
    } else if (depositCount > 10) {
      insight = "Great job on consistent deposits! You're building a strong financial cushion."
    }

    // 3. Store the insight for the user
    await supabase.from('financial_insights').insert({
      user_id: user.id,
      content: insight,
      metadata: { healthScore, totalSpent, depositCount, withdrawalCount }
    })

    return new Response(JSON.stringify({
      success: true,
      healthScore,
      insight,
      summary: {
        totalSpent,
        depositCount,
        withdrawalCount
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error in financial-health-check:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
