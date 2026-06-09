# Help Page Logic Flow

## 1. Frontend Submission (Flutter/Web)
The user provides their information in the inquiry form:
* **Fields:** `firstName`, `lastName`, `email`, and `message`.
* **Action:** When the user clicks "Submit," the app sends a POST request to the Supabase Edge Function endpoint.
* **Implementation:** The app uses `supabase.functions.invoke()` to trigger this flow.

## 2. Supabase Edge Function (send-support-email)
The logic resides in `supabase/functions/send-support-email/index.ts`. Here is what happens inside:
1. **Validation:** The function checks that all four fields are present and not empty.
2. **Secret Retrieval:** It securely pulls SMTP credentials (`SMTP_USER`, `SMTP_PASS`, etc.) from Supabase Project Secrets.
3. **Transport Creation:** It initializes an email transport (currently configured for Gmail/SMTP) using the `nodemailer` library.
4. **Email Formatting:**
    * **Recipient:** The message is hardcoded to be sent to `alphine886@gmail.com`.
    * **Reply-To:** The user's email is set as the reply-to address. This allows you to reply to the inquiry directly from your email client.
    * **Template:** It generates a styled HTML email containing the user's name, email, and the inquiry text.
5. **Execution:** The email is dispatched.

## 3. Database & Persistence (Supabase)
* **Current State:** There is no database storage for help inquiries. The data is transient and exists only during the execution of the Edge Function until it is delivered to the email inbox.
* **Security:** This approach keeps the user's message private (only in your inbox) and avoids cluttering your database with one-off support messages.

## 4. Response Cycle
* **Success:** If the email sends successfully, the function returns a JSON response: `{ "success": true }`.
* **Error:** If the email fails (e.g., wrong SMTP password), it returns an error object which the frontend uses to show a "Please try again later" message.
