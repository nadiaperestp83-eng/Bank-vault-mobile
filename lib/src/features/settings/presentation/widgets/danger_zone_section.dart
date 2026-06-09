import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE DANGER ZONE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.error,
              ),
        ),
        const SizedBox(height: AppSizes.p16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.p20),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.p20),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSizes.p16),
                leading: Container(
                  padding: const EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash2, color: AppColors.error),
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                subtitle: const Text(
                  'Irreversibly remove all your data and assets from Vault OS.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(LucideIcons.chevronRight, color: AppColors.error),
                onTap: () => _showDeletionWorkflow(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeletionWorkflow(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Deletion',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const AccountDeletionWorkflow(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

class AccountDeletionWorkflow extends ConsumerStatefulWidget {
  const AccountDeletionWorkflow({super.key});

  @override
  ConsumerState<AccountDeletionWorkflow> createState() => _AccountDeletionWorkflowState();
}

class _AccountDeletionWorkflowState extends ConsumerState<AccountDeletionWorkflow> {
  int _step = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _assetCheckResult;
  final _emailController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _checkAssets();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkAssets() async {
    final profile = ref.read(profileStreamProvider).value;
    if (profile == null) return;

    try {
      final result = await ref.read(settingsServiceProvider).checkAssetsForDeletion(profile.id);
      if (mounted) {
        setState(() {
          _assetCheckResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Asset check failed: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _requestDeletion() async {
    final profile = ref.read(profileStreamProvider).value;
    final user = ref.read(authServiceProvider).currentUser;
    if (profile == null || user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(settingsServiceProvider).requestAccountDeletion(profile.id, user.email!);
      if (mounted) setState(() => _step = 3);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion request failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _step != 3,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p24)),
        contentPadding: const EdgeInsets.all(AppSizes.p24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 1) _buildAssetCheck(),
            if (_step == 2) _buildConfirmation(),
            if (_step == 3) _buildSuccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCheck() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSizes.p16),
          Text('Performing Asset Check...'),
        ],
      );
    }

    final hasAssets = (_assetCheckResult?['wallet_balance'] as num? ?? 0) > 0 ||
                     (_assetCheckResult?['active_loans'] as int? ?? 0) > 0 ||
                     (_assetCheckResult?['active_savings_goals'] as int? ?? 0) > 0;

    return Column(
      children: [
        const Icon(LucideIcons.search, size: 48, color: AppColors.primary),
        const SizedBox(height: AppSizes.p16),
        const Text(
          'Asset Check',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'Scanning your account for active balances, loans, and goals...',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSizes.p24),
        _buildCheckItem('Wallet Balance', _assetCheckResult?['wallet_balance']?.toString() ?? '0', (_assetCheckResult?['wallet_balance'] as num? ?? 0) == 0),
        _buildCheckItem('Active Loans', _assetCheckResult?['active_loans']?.toString() ?? '0', (_assetCheckResult?['active_loans'] as int? ?? 0) == 0),
        _buildCheckItem('Savings Goals', _assetCheckResult?['active_savings_goals']?.toString() ?? '0', (_assetCheckResult?['active_savings_goals'] as int? ?? 0) == 0),
        const SizedBox(height: AppSizes.p24),
        if (hasAssets) ...[
          const Text(
            'Warning: You have active assets or liabilities. Please clear them before deleting your account.',
            style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Settings'),
            ),
          ),
        ] else ...[
          const Text(
            'All checks passed. You can proceed with deletion.',
            style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCheckItem(String label, String status, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOk ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isOk ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                size: 16,
                color: isOk ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(authServiceProvider).currentUser;

    return Column(
      children: [
        const Icon(LucideIcons.shieldAlert, size: 48, color: AppColors.error),
        const SizedBox(height: AppSizes.p16),
        const Text(
          'Final Confirmation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'To proceed, please type your email address: ${user?.email}',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12),
        ),
        const SizedBox(height: AppSizes.p24),
        TextField(
          controller: _emailController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
          ),
          onChanged: (val) {
            setState(() => _canDelete = val.trim() == user?.email);
          },
        ),
        const SizedBox(height: AppSizes.p24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canDelete ? _requestDeletion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
            ),
            child: const Text('CONFIRM DELETION'),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const Icon(LucideIcons.mailCheck, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSizes.p24),
        const Text(
          'Verification Sent',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p12),
        Text(
          'We have sent a final confirmation link to your email. Your account will be scheduled for deletion once you click it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSizes.p32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
            ),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}
