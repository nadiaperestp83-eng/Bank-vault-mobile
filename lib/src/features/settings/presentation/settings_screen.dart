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
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                // Using a slightly more sophisticated look if possible
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimaryLight),
          ),
          const SizedBox(width: AppSizes.p8),
        ],
      ),
      endDrawer: const ActivityLogDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
        child: Column(
          children: [
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
