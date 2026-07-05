# Vault OS

Vault OS is a highly secure, modern mobile financial and banking application built with Flutter. It provides a robust, protected environment for managing finances, executing transactions, managing savings, and getting insights from an AI Advisor.

## Features

- **Robust Security**: Integrates `secure_application` to protect financial data and blur the screen when sent to the background.
- **Authentication**: Secure user authentication and authorization using Supabase and local biometrics.
- **Dashboard**: A comprehensive overview of your financial health, recent transactions, and accounts.
- **Transactions**: Send and receive money seamlessly.
- **Savings Management**: Track and manage your savings goals.
- **AI Advisor**: Get personalized financial advice and insights powered by AI.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Complex State) & [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (Theme/Simple State)
- **Backend as a Service**: [Supabase](https://supabase.com/)
- **Routing**: [go_router](https://pub.dev/packages/go_router)
- **Networking**: [dio](https://pub.dev/packages/dio) & [http](https://pub.dev/packages/http)
- **Local Storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) & [shared_preferences](https://pub.dev/packages/shared_preferences)

## Getting Started

### Prerequisites

- Flutter SDK (^3.12.1)
- Supabase Project (for backend services)

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd vault-mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration:**
   Create a `.env` file in the root directory and add your Supabase credentials and other required variables:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/src/features/`: Contains feature modules (Auth, Dashboard, Transact, Finance, Help).
- `lib/src/services/`: Services for API and backend integration (e.g., Supabase, Auth, Dashboard).
- `lib/src/routing/`: App routing configuration.
- `lib/src/utils/`: Utility functions and global providers.
- `lib/src/constants/`: App-wide constants (Colors, Theme, etc.).

## Security

Vault OS takes security seriously. It incorporates device-level security checks, secure local storage, network certificate pinning, and background screen obfuscation to ensure user data remains private.
