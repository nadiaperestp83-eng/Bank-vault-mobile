import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/features/transact/presentation/transact_screen.dart';
import 'package:vault_os/src/features/transact/presentation/p2p/recipient_discovery_screen.dart';
import 'package:vault_os/src/features/settings/presentation/settings_screen.dart';
import 'package:vault_os/src/features/help/presentation/help_screen.dart';
import 'package:vault_os/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:vault_os/src/features/finance/presentation/finance_hub_screen.dart';
import 'package:vault_os/src/features/finance/presentation/savings_dashboard_screen.dart';
import 'package:vault_os/src/features/finance/presentation/loans_dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/common_widgets/vault_top_nav.dart';
import 'package:vault_os/src/features/auth/presentation/login_screen.dart';
import 'package:vault_os/src/features/auth/presentation/signup_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void _onTap(BuildContext context, int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/finance');
        break;
      case 2:
        context.go('/transact');
        break;
      case 3:
        context.go('/settings');
        break;
      case 4:
        context.go('/help');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VaultTopNav(),
      extendBodyBehindAppBar: true,
      body: widget.child,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onTap(context, 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(LucideIcons.repeat, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, LucideIcons.home, 'Home'),
              _buildNavItem(1, LucideIcons.landmark, 'Finance'),
              const SizedBox(width: 40), // Spacer for FAB
              _buildNavItem(3, LucideIcons.settings, 'Settings'),
              _buildNavItem(4, LucideIcons.helpCircle, 'Help'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceHubScreen(),
          routes: [
            GoRoute(
              path: 'savings',
              builder: (context, state) => const SavingsDashboardScreen(),
            ),
            GoRoute(
              path: 'loans',
              builder: (context, state) => const LoansDashboardScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/transact',
          builder: (context, state) => const TransactScreen(),
          routes: [
            GoRoute(
              path: 'p2p',
              builder: (context, state) => const RecipientDiscoveryScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/pay/:username',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            // In a real app, we'd fetch the user profile here or pass the tag.
            // For now, we'll assume it's a KYC tag.
            return RecipientDiscoveryScreen(); // Or directly to PaymentDetails if we had the user object.
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpScreen(),
        ),
      ],
    ),
  ],
);
