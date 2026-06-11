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
      pageBuilder: (context, anim1, anim2) => const PINChangeWorkflow(),
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

class PINChangeWorkflow extends ConsumerStatefulWidget {
  const PINChangeWorkflow({super.key});

  @override
  ConsumerState<PINChangeWorkflow> createState() => _PINChangeWorkflowState();
}

class _PINChangeWorkflowState extends ConsumerState<PINChangeWorkflow> {
  int _step = 1;
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleStep() async {
    final settingsService = ref.read(settingsServiceProvider);
    final profile = ref.read(profileStreamProvider).value;
    if (profile == null) return;

    setState(() => _isLoading = true);

    try {
      if (_step == 1) {
        final isValid = await settingsService.verifyCurrentPin(profile.id, _currentPinController.text);
        if (!isValid) throw 'Invalid current PIN';
        
        final email = ref.read(authServiceProvider).currentUser?.email;
        if (email == null) throw 'User email not found';
        await settingsService.requestPinResetOtp(email);
        
        setState(() => _step = 2);
      } else if (_step == 2) {
        if (_newPinController.text != _confirmPinController.text) throw 'PINs do not match';
        if (_newPinController.text.length != 6) throw 'PIN must be 6 digits';

        final email = ref.read(authServiceProvider).currentUser?.email;
        if (email == null) throw 'User email not found';
        
        await settingsService.verifyPinResetOtp(email, _otpController.text);
        await settingsService.updatePin(profile.id, _newPinController.text);
        
        // Save to secure storage for biometrics
        await StorageService().saveCredentials(email, _newPinController.text);
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p24)),
      title: Text(_step == 1 ? 'Verify Identity' : 'Change PIN'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 1) ...[
              const Text('Enter your current 6-digit PIN to begin.'),
              const SizedBox(height: AppSizes.p24),
              _buildPinInput(controller: _currentPinController, label: 'Current PIN'),
            ] else ...[
              const Text('Enter your new PIN and the OTP sent to your email.'),
              const SizedBox(height: AppSizes.p24),
              _buildPinInput(controller: _newPinController, label: 'New PIN'),
              const SizedBox(height: AppSizes.p12),
              _buildPinInput(controller: _confirmPinController, label: 'Confirm New PIN'),
              const SizedBox(height: AppSizes.p12),
              _buildPinInput(controller: _otpController, label: '6-digit OTP'),
            ],
            const SizedBox(height: AppSizes.p24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
                  ),
                  child: Text(_step == 2 ? 'Update PIN' : 'Continue'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInput({required TextEditingController controller, String? label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.p4),
        ],
        TextField(
          controller: controller,
          obscureText: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            counterText: '',
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
