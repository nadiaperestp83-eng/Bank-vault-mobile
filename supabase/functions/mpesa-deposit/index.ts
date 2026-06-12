import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { phoneNumber, amount } = await req.json()

    if (!phoneNumber || !amount) {
      return new Response(JSON.stringify({ error: 'Missing phoneNumber or amount' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. Get OAuth Token
    const consumerKey = Deno.env.get('MPESA_CONSUMER_KEY')
    const consumerSecret = Deno.env.get('MPESA_CONSUMER_SECRET')
    
    if (!consumerKey || !consumerSecret) {
      throw new Error('M-Pesa credentials not configured')
    }

    const auth = btoa(`${consumerKey}:${consumerSecret}`)
    const tokenResponse = await fetch("https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials", {
      headers: { Authorization: `Basic ${auth}` }
    })
    
    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      throw new Error(`Failed to get M-Pesa token: ${errorText}`)
    }
    
    const { access_token } = await tokenResponse.json()

    // 2. Initiate STK Push
    const shortCode = Deno.env.get('MPESA_BUSINESS_SHORT_CODE')
    const passkey = Deno.env.get('MPESA_PASSKEY')
    const callbackUrl = Deno.env.get('MPESA_CALLBACK_URL')
    
    if (!shortCode || !passkey || !callbackUrl) {
      throw new Error('M-Pesa configuration missing (shortCode, passkey, or callbackUrl)')
    }

    const timestamp = new Date().toISOString().replace(/[-:T.Z]/g, "").substring(0, 14)
    const password = btoa(`${shortCode}${passkey}${timestamp}`)

    const stkResponse = await fetch("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${access_token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        BusinessShortCode: shortCode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: Math.round(amount),
        PartyA: phoneNumber,
        PartyB: shortCode,
        PhoneNumber: phoneNumber,
        CallBackURL: callbackUrl,
        AccountReference: "VaultOS",
        TransactionDesc: "Vault OS Deposit"
      })
    })

    const data = await stkResponse.json()

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: stkResponse.ok ? 200 : stkResponse.status,
    })
  } catch (error) {
    console.error('Error in mpesa-deposit:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
