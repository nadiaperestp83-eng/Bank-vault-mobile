import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/preferences_model.dart';
import 'package:vault_os/src/models/profile_model.dart';

class ActivityLogSection extends ConsumerWidget {
  const ActivityLogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(preferencesStreamProvider);
    final profileAsync = ref.watch(profileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY & PREFERENCES',
          style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildRecentLogs(context),
        const SizedBox(height: AppSizes.p16),
        preferencesAsync.when(
          data: (prefs) => prefs != null 
            ? _buildPreferences(context, ref, prefs, profileAsync.value) 
            : const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildRecentLogs(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              TextButton(
                onPressed: () => _showActivityDrawer(context),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          _buildLogItem(context, 'Login', 'Today, 10:45 AM'),
          _buildLogItem(context, 'Profile Update', 'Today, 09:12 AM'),
          _buildLogItem(context, 'Transfer to @sam', 'Yesterday, 04:30 PM'),
          _buildLogItem(context, 'Security PIN Change', 'June 5, 11:20 AM'),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, String action, String timestamp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          Icon(LucideIcons.history, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences(BuildContext context, WidgetRef ref, UserPreferences prefs, Profile? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsService = ref.read(settingsServiceProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTIFICATIONS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: AppSizes.p8),
          _buildPreferenceSwitch(context, 'Transfer Received', prefs.notificationsTransferReceived, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsTransferReceived: v))),
          _buildPreferenceSwitch(context, 'Login Alert', prefs.notificationsAccountLogin, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsAccountLogin: v))),
          _buildPreferenceSwitch(context, 'AI Insights', prefs.notificationsAiInsights, 
            (v) => settingsService.updatePreferences(prefs.copyWith(notificationsAiInsights: v))),
          const Divider(height: AppSizes.p24),
          const Text(
            'SYSTEM',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: AppSizes.p16),
          _buildDropdown(context, 'Primary Currency', profile?.primaryCurrency ?? 'KES', ['USD', 'KES', 'EUR', 'GBP'], 
            (v) => settingsService.updateCurrency(prefs.userId, v!)),
          const SizedBox(height: AppSizes.p12),
          _buildDropdown(context, 'App Theme', prefs.theme.substring(0, 1).toUpperCase() + prefs.theme.substring(1), ['Light', 'Dark', 'System'], 
            (v) => settingsService.updateTheme(prefs.userId, v!.toLowerCase())),
          const SizedBox(height: AppSizes.p12),
          _buildDropdown(context, 'Language', prefs.language, ['en', 'sw', 'fr'], 
            (v) => settingsService.updateLanguage(prefs.userId, v!)),
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

  Widget _buildDropdown(BuildContext context, String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safety check: ensure value exists in items
    final String effectiveValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: AppSizes.p4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppSizes.p12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.darkBackground : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityDrawer(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }
}

class ActivityLogDrawer extends StatelessWidget {
  const ActivityLogDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, color: AppColors.primary),
                  const SizedBox(width: AppSizes.p16),
                  Text(
                    'Full Activity Log',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                itemCount: 20,
                separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Action $index', 
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'June ${8 - (index ~/ 3)}, 2026', 
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight, 
                      size: 16,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
