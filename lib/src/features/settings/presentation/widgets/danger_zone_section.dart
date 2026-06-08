import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class DangerZoneSection extends StatelessWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.error.withOpacity(0.1),
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
                border: Border.all(color: AppColors.error.withOpacity(0.5), width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSizes.p16),
                leading: Container(
                  padding: const EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
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
      pageBuilder: (context, anim1, anim2) => const _AccountDeletionWorkflow(),
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

class _AccountDeletionWorkflow extends StatefulWidget {
  const _AccountDeletionWorkflow();

  @override
  State<_AccountDeletionWorkflow> createState() => _AccountDeletionWorkflowState();
}

class _AccountDeletionWorkflowState extends State<_AccountDeletionWorkflow> {
  int _step = 1;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isScanning = false);
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
        if (_isScanning)
          const CircularProgressIndicator()
        else ...[
          _buildCheckItem('Wallet Balance', 'Empty', true),
          _buildCheckItem('Active Loans', 'None', true),
          _buildCheckItem('Savings Goals', '1 Active', false),
          const SizedBox(height: AppSizes.p24),
          const Text(
            'Warning: You still have an active savings goal. Deleting your account will forfeit these funds.',
            style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
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
          'This action is IRREVERSIBLE. Please enter your credentials to confirm.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSizes.p24),
        TextField(
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Email Address',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        TextField(
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 3),
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
              Navigator.pop(context); // Close dialog
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
            ),
            child: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}
