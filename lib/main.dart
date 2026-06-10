import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:vault_os/src/services/supabase_service.dart';
import 'package:vault_os/src/routing/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:vault_os/src/services/auth_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/utils/theme_provider.dart';

import 'package:vault_os/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:vault_os/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';
import 'package:vault_os/src/features/finance/presentation/bloc/savings_bloc.dart';
import 'package:vault_os/src/features/help/presentation/bloc/ai_advisor_bloc.dart';
import 'package:vault_os/src/services/dashboard_service.dart';
import 'package:vault_os/src/services/transaction_service.dart';
import 'package:vault_os/src/services/savings_service.dart';
import 'package:vault_os/src/services/ai_advisor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_KEY']!;
  await Stripe.instance.applySettings();

  final authService = AuthService();
  final dashboardService = DashboardService();
  final transactionService = TransactionService();
  final savingsService = SavingsService();
  final aiAdvisorService = AiAdvisorService();

  runApp(
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authService: authService,
            )..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              dashboardService: dashboardService,
            ),
          ),
          BlocProvider(
            create: (context) => TransactionBloc(
              transactionService: transactionService,
            ),
          ),
          BlocProvider(
            create: (context) => SavingsBloc(
              savingsService: savingsService,
            ),
          ),
          BlocProvider(
            create: (context) => AiAdvisorBloc(
              aiAdvisorService: aiAdvisorService,
            ),
          ),
        ],
        child: const VaultOSApp(),
      ),
    ),
  );
}

class VaultOSApp extends ConsumerWidget {
  const VaultOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Vault OS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
