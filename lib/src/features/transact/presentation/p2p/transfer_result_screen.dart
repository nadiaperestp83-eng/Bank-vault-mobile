import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class TransferResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final VaultUser recipient;
  final double amount;
  final String currency;

  const TransferResultScreen({
    super.key,
    required this.isSuccess,
    required this.message,
    required this.recipient,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                isSuccess ? 'Payment Successful' : 'Payment Failed',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
              ),
              if (isSuccess) ...[
                const SizedBox(height: 48),
                _buildTransactionSummary(),
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
        isSuccess ? LucideIcons.checkCircle2 : LucideIcons.zap, // Zap for error as requested/aesthetic
        color: isSuccess ? Colors.green : Colors.red,
        size: 56,
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).shake(delay: 500.ms);
  }

  Widget _buildTransactionSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recipient', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              Text('${recipient.firstName} ${recipient.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              Text(CurrencyFormatter.format(amount, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDoneButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
