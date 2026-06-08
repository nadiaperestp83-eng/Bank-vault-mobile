import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class ActivityLogSection extends StatefulWidget {
  const ActivityLogSection({super.key});

  @override
  State<ActivityLogSection> createState() => _ActivityLogSectionState();
}

class _ActivityLogSectionState extends State<ActivityLogSection> {
  bool _notifTransfer = true;
  bool _notifLogin = true;
  bool _notifAI = false;

  String _currency = 'USD';
  String _theme = 'System';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY & PREFERENCES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildRecentLogs(context),
        const SizedBox(height: AppSizes.p16),
        _buildPreferences(),
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
          _buildLogItem('Login', 'Today, 10:45 AM'),
          _buildLogItem('Profile Update', 'Today, 09:12 AM'),
          _buildLogItem('Transfer to @sam', 'Yesterday, 04:30 PM'),
          _buildLogItem('Security PIN Change', 'June 5, 11:20 AM'),
        ],
      ),
    );
  }

  Widget _buildLogItem(String action, String timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          const Icon(LucideIcons.history, size: 14, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            timestamp,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTIFICATIONS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: AppSizes.p8),
          _buildPreferenceSwitch('Transfer Received', _notifTransfer, (v) => setState(() => _notifTransfer = v)),
          _buildPreferenceSwitch('Login Alert', _notifLogin, (v) => setState(() => _notifLogin = v)),
          _buildPreferenceSwitch('AI Insights', _notifAI, (v) => setState(() => _notifAI = v)),
          const Divider(height: AppSizes.p24),
          const Text(
            'SYSTEM',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: AppSizes.p16),
          _buildDropdown('Primary Currency', _currency, ['USD', 'KES', 'EUR', 'GBP'], (v) => setState(() => _currency = v!)),
          const SizedBox(height: AppSizes.p12),
          _buildDropdown('App Theme', _theme, ['Light', 'Dark', 'System'], (v) => setState(() => _theme = v!)),
          const SizedBox(height: AppSizes.p12),
          _buildDropdown('Language', _language, ['English', 'Swahili', 'French'], (v) => setState(() => _language = v!)),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(String title, bool value, ValueChanged<bool> onChanged) {
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
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        const SizedBox(height: AppSizes.p4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppSizes.p12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
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
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
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
                  const Text(
                    'Full Activity Log',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                itemCount: 20,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Action $index', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('June ${8 - (index ~/ 3)}, 2026', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
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
