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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authState = context.watch<AuthBloc>().state;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkBackground.withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : AppColors.lightBorder.withOpacity(0.5),
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
                
                // Right Section: Interaction Hub
                if (authState is VaultAuthenticated) ...[
                  _buildGreeting(context),
                  const SizedBox(width: AppSizes.p12),
                  _buildInteractionHub(context, ref, isDark),
                ] else ...[
                  _buildLandingButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, VaultAuthState authState) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (authState is VaultAuthenticated) {
          context.go('/');
        } else {
          context.go('/login'); // Link to login/root
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
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
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const Text(
              'Stephen', // Placeholder name
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractionHub(BuildContext context, WidgetRef ref, bool isDark) {
    return Row(
      children: [
        _buildNavButton(
          icon: isDark ? LucideIcons.sun : LucideIcons.moon,
          color: isDark ? Colors.yellow : const Color(0xFF64748B),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
          isCircular: true,
          hasGlow: true,
        ),
        const SizedBox(width: 10),
        _buildNavButton(
          icon: LucideIcons.receiptText,
          onTap: () {
            HapticFeedback.lightImpact();
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
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isCircular = false,
    bool hasGlow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isCircular ? 20 : 10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: hasGlow ? [
            BoxShadow(
              color: (color ?? AppColors.primary).withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.white, strokeWidth: 1.5),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildNavButton(
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
            decoration: const BoxDecoration(
              color: AppColors.error,
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
          border: Border.all(color: AppColors.darkPrimary, width: 2),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
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
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
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
                  color: Colors.grey.withOpacity(0.3),
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
      leading: Icon(icon, color: color, size: 20, strokeWidth: 1.5),
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

  Widget _buildLandingButtons(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/login');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/signup');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
          ),
          child: const Text('Get Started', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
