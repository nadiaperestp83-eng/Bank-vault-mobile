import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/preferences_model.dart';
import 'package:vault_os/src/models/profile_model.dart';

class SystemSection extends ConsumerWidget {
  const SystemSection({super.key});

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
          'SYSTEM PREFERENCES',
          style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        preferencesAsync.when(
          data: (prefs) => prefs != null 
            ? _buildSystem(context, ref, prefs, profileAsync.value) 
            : const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSystem(BuildContext context, WidgetRef ref, UserPreferences prefs, Profile? profile) {
    final settingsService = ref.read(settingsServiceProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
}
