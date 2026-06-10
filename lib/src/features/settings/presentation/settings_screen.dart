import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'widgets/profile_section.dart';
import 'widgets/business_profile_section.dart';
import 'widgets/security_center_section.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/system_section.dart';
import 'widgets/danger_zone_section.dart';
import 'widgets/activity_log_drawer.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileStreamProvider);

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
                const SizedBox(width: AppSizes.p8),
                profileAsync.when(
                  data: (profile) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      image: DecorationImage(
                        image: profile?.profilePhotoUrl != null
                            ? NetworkImage(profile!.profilePhotoUrl!)
                            : const NetworkImage('https://i.pravatar.cc/300'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                    child: Icon(LucideIcons.user, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),
            const ProfileSection(),
            const SizedBox(height: AppSizes.p32),
            const SystemSection(),
            const SizedBox(height: AppSizes.p32),
            const SecurityCenterSection(),
            const SizedBox(height: AppSizes.p32),
            const RecentActivitySection(),
            const SizedBox(height: AppSizes.p32),
            const BusinessProfileSection(),
            const SizedBox(height: AppSizes.p32),
            const NotificationsSection(),
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
