import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'widgets/profile_section.dart';
import 'widgets/business_profile_section.dart';
import 'widgets/security_center_section.dart';
import 'widgets/activity_log_section.dart';
import 'widgets/danger_zone_section.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      endDrawer: const ActivityLogDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
        child: Column(
          children: [
            const SizedBox(height: 64), // Space for VaultTopNav
            Row(
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    LucideIcons.bell,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),
            const ProfileSection(),
            const SizedBox(height: AppSizes.p32),
            const BusinessProfileSection(),
            const SizedBox(height: AppSizes.p32),
            const SecurityCenterSection(),
            const SizedBox(height: AppSizes.p32),
            const ActivityLogSection(),
            const SizedBox(height: AppSizes.p32),
            const DangerZoneSection(),
            const SizedBox(height: AppSizes.p32),
            _buildSignOutButton(context),
            const SizedBox(height: AppSizes.p64), // Extra padding for bottom dock clearance
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Logic for actual sign out would go here (e.g., authBloc.add(SignOutRequested()))
          context.go('/login');
        },
        icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.error),
        label: const Text(
          'SIGN OUT OF VAULT',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
