import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import nodemailer from "https://esm.sh/nodemailer"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, email } = await req.json()

    if (!userId || !email) {
      return new Response(JSON.stringify({ error: 'Missing userId or email' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const transporter = nodemailer.createTransport({
      host: Deno.env.get('SMTP_HOST'),
      port: Number(Deno.env.get('SMTP_PORT')),
      secure: true,
      auth: {
        user: Deno.env.get('SMTP_USER'),
        pass: Deno.env.get('SMTP_PASS'),
      },
    })

    const mailOptions = {
      from: '"Vault OS Security" <security@vault-os.com>',
      to: email,
      subject: "Important: Account Deletion Request Received",
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ffcccc; border-radius: 10px;">
          <h2 style="color: #d9534f;">Account Deletion Request</h2>
          <p>We received a request to permanently delete your Vault OS account (User ID: ${userId}).</p>
          <p style="color: #555;">If you did NOT initiate this request, please contact our support team immediately at <strong>support@vault-os.com</strong> and change your security PIN.</p>
          <div style="background-color: #fcf8e3; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #faebcc; color: #8a6d3b;">
            <strong>Warning:</strong> Account deletion is permanent and cannot be undone. All your funds must be withdrawn before the account can be fully closed.
          </div>
          <p>Your account will enter a 30-day "Pending Deletion" state before being permanently erased.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin-top: 30px;" />
          <p style="font-size: 12px; color: #999; text-align: center;">This is an automated security notification from Vault OS.</p>
        </div>
      `,
    }

    await transporter.sendMail(mailOptions)

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error in send-predelete-email:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
