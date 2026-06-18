import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/device_model.dart';
import 'package:vault_os/src/models/preferences_model.dart';
import 'package:vault_os/src/models/profile_model.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/services/storage_service.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';

class SecurityCenterSection extends ConsumerWidget {
  const SecurityCenterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(preferencesStreamProvider);
    final devicesAsync = ref.watch(devicesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECURITY CENTER',
          style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildAlertFeed(context),
        const SizedBox(height: AppSizes.p16),
        preferencesAsync.when(
          data: (prefs) => prefs != null ? _buildSecurityToggles(context, ref, prefs) : const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSizes.p16),
        devicesAsync.when(
          data: (devices) => _buildDeviceManagement(context, ref, devices),
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildPINControl(context),
      ],
    );
  }

  Widget _buildAlertFeed(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldAlert, size: 18, color: AppColors.error),
              const SizedBox(width: AppSizes.p8),
              const Text(
                'Recent Security Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          _buildAlertItem(context, 'Unusual Login - Nairobi, KE', '2 mins ago', AppColors.error),
          _buildAlertItem(context, 'Password Changed', 'Yesterday', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, String title, String time, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityToggles(BuildContext context, WidgetRef ref, UserPreferences prefs) {
    return GlassCard(
      child: Column(
        children: [
          _buildToggleRow(
            context,
            'Biometric Authentication',
            'Use FaceID or Fingerprint',
            LucideIcons.fingerprint,
            prefs.biometricEnabled,
            (v) async {
              await ref.read(settingsServiceProvider).updatePreferences(prefs.copyWith(biometricEnabled: v));
              // Also update local StorageService
              await StorageService().setBiometricEnabled(v);
            },
          ),
          const Divider(height: AppSizes.p24),
          _buildToggleRow(
            context,
            'Two-Factor Auth (2FA)',
            'Extra layer of security',
            LucideIcons.shieldCheck,
            prefs.notificationsAccountLogin,
            (v) => ref.read(settingsServiceProvider).updatePreferences(prefs.copyWith(notificationsAccountLogin: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDeviceManagement(BuildContext context, WidgetRef ref, List<UserDevice> devices) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUTHORIZED DEVICES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: AppSizes.p16),
          ...devices.where((d) => d.isActive).map((device) => _buildDeviceItem(context, ref, device)),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, WidgetRef ref, UserDevice device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          Icon(device.deviceType == 'mobile' ? LucideIcons.smartphone : LucideIcons.laptop, 
               size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.deviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(device.isActive ? 'Active' : 'Inactive', 
                     style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(settingsServiceProvider).revokeDevice(device.id),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Revoke', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPINControl(BuildContext context) {
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(LucideIcons.keyRound, color: AppColors.primary),
        title: const Text('Change Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Secure multi-step update', style: TextStyle(fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/settings/change-pin');
        },
      ),
    );
  }
}

