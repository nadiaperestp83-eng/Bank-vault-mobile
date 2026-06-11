import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/services/dashboard_service.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'withdrawal_setup_screen.dart';

class WithdrawalAmountScreen extends StatefulWidget {
  const WithdrawalAmountScreen({super.key});

  @override
  State<WithdrawalAmountScreen> createState() => _WithdrawalAmountScreenState();
}

class _WithdrawalAmountScreenState extends State<WithdrawalAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final DashboardService _dashboardService = DashboardService();
  Wallet? _currentWallet;
  StreamSubscription? _walletSubscription;
  final double _exchangeRate = 130.0;

  @override
  void initState() {
    super.initState();
    _walletSubscription = _dashboardService.getWalletStream().listen((wallet) {
      if (mounted) setState(() => _currentWallet = wallet);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletSubscription?.cancel();
    super.dispose();
  }

  void _onNext() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalSetupScreen(amount: amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final kesEquivalent = amount * _exchangeRate;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text('Enter Withdrawal Amount', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
            const SizedBox(height: 16),
            _buildAmountInput(primaryTextColor, isDark),
            const SizedBox(height: 24),
            _buildEquivalentBox(kesEquivalent),
            const SizedBox(height: 48),
            _buildBalanceInfo(secondaryTextColor, isDark),
            const SizedBox(height: 48),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(Color primaryTextColor, bool isDark) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryTextColor),
      onChanged: (v) => setState(() {}),
      decoration: InputDecoration(
        hintText: '0.00',
        border: InputBorder.none,
        hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey),
        prefixText: '\$ ',
        prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[700] : Colors.grey),
      ),
      autofocus: true,
    );
  }

  Widget _buildEquivalentBox(double amountKES) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        '≈ ${CurrencyFormatter.format(amountKES, 'KES')}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildBalanceInfo(Color secondaryTextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.wallet, size: 16, color: secondaryTextColor),
          const SizedBox(width: 8),
          Text(
            'Available: ${CurrencyFormatter.format(_currentWallet?.balance ?? 0.0, _currentWallet?.currency ?? 'KES')}',
            style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    bool isValid = amount > 0 && amount <= (_currentWallet?.balance ?? 0.0);

    return ElevatedButton(
      onPressed: isValid ? _onNext : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: isValid ? 10 : 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: const Text('Continue to Bank Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
