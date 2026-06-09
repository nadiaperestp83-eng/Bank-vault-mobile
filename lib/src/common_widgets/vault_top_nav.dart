import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/utils/theme_provider.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VaultTopNav extends ConsumerWidget implements PreferredSizeWidget {
  const VaultTopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : theme.dividerTheme.color?.withValues(alpha: 0.5) ?? theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Left Section: Branding
                _buildLogo(context, authState),
                
                const Spacer(),
                
                // Right Section: Interaction Hub (Always visible)
                _buildGreeting(context),
                const SizedBox(width: AppSizes.p12),
                _buildInteractionHub(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, VaultAuthState authState) {
    final theme = Theme.of(context);
    final currentPath = GoRouterState.of(context).uri.path;
    final isLanding = currentPath == '/login' || currentPath == '/signup';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isLanding) {
          context.go('/login');
        } else {
          context.go('/');
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'V',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '🌅';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.of(context).size.width < 450) return const SizedBox.shrink();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$greeting, $emoji',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              'Stephen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractionHub(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _buildNavButton(
          context: context,
          icon: isDark ? LucideIcons.sun : LucideIcons.moon,
          color: isDark ? Colors.yellow : const Color(0xFF64748B),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark);
          },
          isCircular: true,
          hasGlow: true,
        ),
        const SizedBox(width: 10),
        _buildNavButton(
          context: context,
          icon: LucideIcons.receiptText,
          onTap: () {
            HapticFeedback.lightImpact();
            // Show digital receipts logic
          },
        ),
        const SizedBox(width: 10),
        _buildNotificationButton(context),
        const SizedBox(width: 10),
        _buildProfileTrigger(context),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isCircular = false,
    bool hasGlow = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultIconColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isCircular ? 20 : 10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: hasGlow ? [
            BoxShadow(
              color: (color ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Icon(icon, size: 18, color: color ?? defaultIconColor),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildNavButton(
          context: context,
          icon: LucideIcons.bell,
          onTap: () {
            HapticFeedback.lightImpact();
          },
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: const Text(
              '3',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms, curve: Curves.easeInOut)
           .then()
           .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1000.ms, curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildProfileTrigger(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showProfileBottomSheet(context);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'SM',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.user,
                title: 'View Profile',
                onTap: () => Navigator.pop(context),
              ),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              const Divider(indent: 20, endIndent: 20, height: 1),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
