import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class WithdrawalResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic> details;
  final double amount;
  final String? transactionId;

  const WithdrawalResultScreen({
    super.key,
    required this.isSuccess,
    required this.message,
    required this.details,
    required this.amount,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildStatusIcon(),
              const SizedBox(height: 32),
              Text(
                isSuccess ? 'Withdrawal Successful' : 'Withdrawal Failed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: primaryTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              if (isSuccess) ...[
                const SizedBox(height: 48),
                _buildTransactionSummary(secondaryTextColor, isDark, primaryTextColor),
              ],
              const Spacer(),
              _buildDoneButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? LucideIcons.checkCircle2 : LucideIcons.zap,
        color: isSuccess ? Colors.green : Colors.red,
        size: 56,
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).shake(delay: 500.ms);
  }

  Widget _buildTransactionSummary(Color secondaryTextColor, bool isDark, Color primaryTextColor) {
    final provider = details['provider'];
    final account = details['accountNumber'] ?? details['phoneNumber'];
    final reference = transactionId ?? 'WTH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _summaryRow('Reference', reference, secondaryTextColor, primaryTextColor),
          const SizedBox(height: 12),
          _summaryRow('Destination', provider.toString().toUpperCase(), secondaryTextColor, primaryTextColor),
          const SizedBox(height: 12),
          _summaryRow('Account/Phone', account.toString(), secondaryTextColor, primaryTextColor),
          const Divider(height: 32),
          _summaryRow('Amount', CurrencyFormatter.format(amount, 'USD'), secondaryTextColor, primaryTextColor, isBold: true),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _summaryRow(String label, String value, Color secondaryTextColor, Color primaryTextColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/dashboard'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
