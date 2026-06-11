import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/common_widgets/pin_entry_sheet.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'withdrawal_result_screen.dart';

class WithdrawalConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> details;
  final double amount;
  const WithdrawalConfirmationScreen({super.key, required this.details, required this.amount});

  @override
  State<WithdrawalConfirmationScreen> createState() => _WithdrawalConfirmationScreenState();
}

class _WithdrawalConfirmationScreenState extends State<WithdrawalConfirmationScreen> {
  bool _isProcessing = false;

  void _onConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(
        onConfirm: (pin) {
          setState(() => _isProcessing = true);
          context.read<TransactionBloc>().add(PerformWithdrawal(
            amount: widget.amount,
            method: widget.details['provider'],
            currency: 'USD', // Defaulting to USD as per the flow
            description: widget.details['description'] ?? 'Withdrawal',
            details: widget.details,
            pin: pin,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    final fee = widget.amount * 0.01;
    final total = widget.amount + fee;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          setState(() => _isProcessing = false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => WithdrawalResultScreen(
                isSuccess: true,
                message: state.message,
                details: widget.details,
                amount: widget.amount,
              ),
            ),
            (route) => route.isFirst,
          );
        } else if (state is TransactionError) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Review Withdrawal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(fee, total, secondaryTextColor, primaryTextColor, surfaceColor, borderColor),
                  const SizedBox(height: 32),
                  const Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildDestinationCard(secondaryTextColor, surfaceColor, borderColor),
                  const Spacer(),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double fee, double total, Color secondaryTextColor, Color primaryTextColor, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Total Deduction', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total, 'USD'),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryTextColor),
          ),
          const Divider(height: 48),
          _summaryRow('Withdrawal Amount', CurrencyFormatter.format(widget.amount, 'USD'), secondaryTextColor, primaryTextColor),
          const SizedBox(height: 16),
          _summaryRow('Platform Fee (1%)', CurrencyFormatter.format(fee, 'USD'), secondaryTextColor, primaryTextColor, isRed: true),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _summaryRow(String label, String value, Color secondaryTextColor, Color primaryTextColor, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red : primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(Color secondaryTextColor, Color surfaceColor, Color borderColor) {
    final provider = widget.details['provider'];
    final account = widget.details['accountNumber'] ?? widget.details['phoneNumber'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.details['channel'] == 'bank' ? LucideIcons.building : LucideIcons.smartphone,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(account.toString(), style: TextStyle(color: secondaryTextColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: const Text('Confirm & Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            const SizedBox(height: 24),
            const Text(
              'Authorizing Withdrawal...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none),
            ).animate(onPlay: (controller) => controller.repeat())
             .fadeIn(duration: 1.seconds)
             .then()
             .fadeOut(duration: 1.seconds),
          ],
        ),
      ),
    );
  }
}
