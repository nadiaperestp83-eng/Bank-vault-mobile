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
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            supabaseClient: Supabase.instance.client,
          )..add(AppStarted()),
        ),
      ],
      child: const VaultOSApp(),
    ),
  );
}

class VaultOSApp extends StatelessWidget {
  const VaultOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vault OS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
