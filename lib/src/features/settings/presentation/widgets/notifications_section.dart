import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/preferences_model.dart';

class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(preferencesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATIONS',
          style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        preferencesAsync.when(
          data: (prefs) => prefs != null 
            ? _buildNotifications(context, ref, prefs) 
            : const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context, WidgetRef ref, UserPreferences prefs) {
    final settingsService = ref.read(settingsServiceProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreferenceSwitch(context, 'Transfer Received', prefs.notificationsTransferReceived, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsTransferReceived: v))),
          _buildPreferenceSwitch(context, 'Login Alert', prefs.notificationsAccountLogin, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsAccountLogin: v))),
          _buildPreferenceSwitch(context, 'AI Insights', prefs.notificationsAiInsights, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsAiInsights: v))),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
