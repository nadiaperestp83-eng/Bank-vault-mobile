import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:vault_os/src/services/supabase_service.dart';
import 'package:vault_os/src/routing/app_router.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_event.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_KEY']!;
  await Stripe.instance.applySettings();

  runApp(
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              supabaseClient: Supabase.instance.client,
            )..add(AppStarted()),
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
