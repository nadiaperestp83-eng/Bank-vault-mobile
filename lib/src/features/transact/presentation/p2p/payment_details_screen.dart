import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_state.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/common_widgets/pin_entry_sheet.dart';
import 'package:vault_os/src/services/dashboard_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/services/biometric_service.dart';
import 'package:vault_os/src/services/storage_service.dart';
import 'transfer_result_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final VaultUser recipient;
  const PaymentDetailsScreen({super.key, required this.recipient});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final DashboardService _dashboardService = DashboardService();
  final BiometricService _biometricService = BiometricService();
  final StorageService _storageService = StorageService();
  Wallet? _currentWallet;
  StreamSubscription? _walletSubscription;
  String _selectedCurrency = 'KES';

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

  Future<void> _handlePaymentConfirmation() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final isBiometricAvailable = await _biometricService.isBiometricAvailable();
    final isBiometricEnabled = await _storageService.isBiometricEnabled();

    if (isBiometricAvailable && isBiometricEnabled) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to confirm payment of $_selectedCurrency $amount to ${widget.recipient.firstName}',
      );

      if (authenticated) {
        final credentials = await _storageService.getCredentials();
        final storedPin = credentials['pin'];

        if (storedPin != null) {
          if (mounted) {
            context.read<TransactionBloc>().add(PerformVaultTransfer(
              recipientTag: widget.recipient.kycTag!,
              amount: amount,
              currency: _selectedCurrency,
              pin: storedPin,
            ));
          }
          return;
        }
      }
    }

    // Fallback to PIN entry sheet
    if (mounted) _showPinSheet();
  }

  void _showPinSheet() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(
        onConfirm: (pin) {
          context.read<TransactionBloc>().add(PerformVaultTransfer(
            recipientTag: widget.recipient.kycTag!,
            amount: amount,
            currency: _selectedCurrency,
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

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TransferResultScreen(
                isSuccess: true,
                message: state.message,
                recipient: widget.recipient,
                amount: double.tryParse(_amountController.text) ?? 0.0,
                currency: _selectedCurrency,
              ),
            ),
          );
        } else if (state is TransactionError) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransferResultScreen(
                isSuccess: false,
                message: state.message,
                recipient: widget.recipient,
                amount: double.tryParse(_amountController.text) ?? 0.0,
                currency: _selectedCurrency,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
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
              _buildRecipientHeader(secondaryTextColor),
              const SizedBox(height: 48),
              _buildAmountInput(secondaryTextColor, isDark),
              const SizedBox(height: 48),
              _buildBalanceInfo(secondaryTextColor, isDark),
              const SizedBox(height: 48),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientHeader(Color secondaryTextColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            (widget.recipient.firstName?[0] ?? '') + (widget.recipient.lastName?[0] ?? ''),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.recipient.firstName} ${widget.recipient.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(
          widget.recipient.kycTag ?? '',
          style: TextStyle(color: secondaryTextColor, fontSize: 14),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildAmountInput(Color secondaryTextColor, bool isDark) {
    return Column(
      children: [
        Text('Enter Amount', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedCurrency = _selectedCurrency == 'KES' ? 'USD' : 'KES'),
              child: Text(
                _selectedCurrency,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey),
                ),
                autofocus: true,
              ),
            ),
          ],
        ),
      ],
    );
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
            'Balance: ${CurrencyFormatter.format(_currentWallet?.balance ?? 0.0, _currentWallet?.currency ?? 'KES')}',
            style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final isLoading = state is TransactionLoading || state is TransactionInProgress;
        return ElevatedButton(
          onPressed: isLoading ? null : _handlePaymentConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 10,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }
}
