import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'widgets/profile_section.dart';
import 'widgets/business_profile_section.dart';
import 'widgets/security_center_section.dart';
import 'widgets/activity_log_section.dart';
import 'widgets/danger_zone_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                  icon: const Icon(LucideIcons.bell, color: AppColors.textPrimaryLight),
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
            const SizedBox(height: AppSizes.p48), // Bottom padding for FAB clearance if needed
          ],
        ),
      ),
    );
  }
}
