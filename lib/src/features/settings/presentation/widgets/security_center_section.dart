import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class SecurityCenterSection extends StatefulWidget {
  const SecurityCenterSection({super.key});

  @override
  State<SecurityCenterSection> createState() => _SecurityCenterSectionState();
}

class _SecurityCenterSectionState extends State<SecurityCenterSection> {
  bool _isBiometricEnabled = true;
  bool _is2FAEnabled = false;

  @override
  Widget build(BuildContext context) {
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
        _buildAlertFeed(),
        const SizedBox(height: AppSizes.p16),
        _buildSecurityToggles(),
        const SizedBox(height: AppSizes.p16),
        _buildDeviceManagement(),
        const SizedBox(height: AppSizes.p16),
        _buildPINControl(),
      ],
    );
  }

  Widget _buildAlertFeed() {
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
          _buildAlertItem('Unusual Login - Nairobi, KE', '2 mins ago', AppColors.error),
          _buildAlertItem('Password Changed', 'Yesterday', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String time, Color statusColor) {
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

  Widget _buildSecurityToggles() {
    return GlassCard(
      child: Column(
        children: [
          _buildToggleRow(
            'Biometric Authentication',
            'Use FaceID or Fingerprint',
            LucideIcons.fingerprint,
            _isBiometricEnabled,
            (v) => setState(() => _isBiometricEnabled = v),
          ),
          const Divider(height: AppSizes.p24),
          _buildToggleRow(
            'Two-Factor Auth (2FA)',
            'Extra layer of security',
            LucideIcons.shieldCheck,
            _is2FAEnabled,
            (v) => setState(() => _is2FAEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
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

  Widget _buildDeviceManagement() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUTHORIZED DEVICES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: AppSizes.p16),
          _buildDeviceItem('iPhone 15 Pro', 'Current Device', LucideIcons.smartphone),
          const Divider(height: AppSizes.p16),
          _buildDeviceItem('MacBook Air M2', 'Last login: 2 hrs ago', LucideIcons.laptop),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(String name, String status, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(status, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ),
        ),
        if (status != 'Current Device')
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Revoke', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPINControl() {
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(LucideIcons.keyRound, color: AppColors.primary),
        title: const Text('Change Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Last updated 3 months ago', style: TextStyle(fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: () => _showChangePINDialog(context),
      ),
    );
  }

  void _showChangePINDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const _PINChangeWorkflow(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

class _PINChangeWorkflow extends StatefulWidget {
  const _PINChangeWorkflow();

  @override
  State<_PINChangeWorkflow> createState() => _PINChangeWorkflowState();
}

class _PINChangeWorkflowState extends State<_PINChangeWorkflow> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p24)),
      title: Text(_step == 1 ? 'Current PIN' : _step == 2 ? 'New PIN' : 'OTP Verification'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 1) ...[
              const Text('Enter your current 6-digit security PIN to continue.'),
              const SizedBox(height: AppSizes.p24),
              _buildPinInput(),
            ] else if (_step == 2) ...[
              const Text('Enter and confirm your new security PIN.'),
              const SizedBox(height: AppSizes.p24),
              _buildPinInput(label: 'New PIN'),
              const SizedBox(height: AppSizes.p12),
              _buildPinInput(label: 'Confirm PIN'),
            ] else ...[
              const Text('We sent a verification code to your email.'),
              const SizedBox(height: AppSizes.p24),
              _buildPinInput(label: '6-digit OTP'),
            ],
            const SizedBox(height: AppSizes.p24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_step < 3) {
                    setState(() => _step++);
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
                ),
                child: Text(_step == 3 ? 'Verify & Change' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInput({String? label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.p4),
        ],
        TextField(
          obscureText: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.p12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.p12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            hintText: '••••••',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
          ),
        ),
      ],
    );
  }
}
