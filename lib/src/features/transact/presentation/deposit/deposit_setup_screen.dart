import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/common_widgets/pin_entry_sheet.dart';
import 'package:vault_os/src/services/transaction_service.dart';
import 'package:vault_os/src/models/vault_models.dart';

class DepositSetupScreen extends StatefulWidget {
  final String method;
  const DepositSetupScreen({super.key, required this.method});

  @override
  State<DepositSetupScreen> createState() => _DepositSetupScreenState();
}

class _DepositSetupScreenState extends State<DepositSetupScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TransactionService _txService = TransactionService();
  List<Map<String, dynamic>> _systemAccounts = [];
  bool _isLoadingAccounts = false;
  VaultUser? _currentUser;
  bool _isAddingNew = false;
  bool _rememberNumber = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.method == 'bank') {
      _loadSystemAccounts();
    }
    _currentUser = await _txService.getCurrentUserProfile();
    if (_currentUser?.phoneNumber != null) {
      _phoneController.text = _currentUser!.phoneNumber!;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadSystemAccounts() async {
    setState(() => _isLoadingAccounts = true);
    try {
      _systemAccounts = await _txService.getSystemBankAccounts();
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onDeposit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    if (widget.method == 'bank') {
      // Manual bank transfer just shows info, no RPC execution here usually
      return;
    }

    final phoneNumber = _isAddingNew ? _phoneController.text : (_currentUser?.phoneNumber ?? _phoneController.text);

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(
        onConfirm: (pin) async {
          if (widget.method == 'mpesa') {
            final phoneNumber = _isAddingNew ? _phoneController.text : (_currentUser?.phoneNumber ?? _phoneController.text);
            if (_isAddingNew && _rememberNumber) {
              await _txService.updateProfilePhoneNumber(phoneNumber);
            }
            if (mounted) {
              context.read<TransactionBloc>().add(PerformMpesaDeposit(
                phoneNumber: phoneNumber,
                amount: amount,
                pin: pin,
              ));
            }
          } else if (widget.method == 'card') {
            context.read<TransactionBloc>().add(PerformStripeDeposit(
              amount: amount,
              currency: 'USD',
              pin: pin,
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          Navigator.pop(context); // Close setup
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is TransactionTimeout) {
          Navigator.pop(context); // Close setup as it's pending
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.orange),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('${widget.method.toUpperCase()} Deposit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.method == 'bank') _buildBankInfo(secondaryTextColor) else ...[
                _buildAmountInput(secondaryTextColor),
                const SizedBox(height: 32),
                if (widget.method == 'mpesa') _buildMpesaField(isDark),
                const SizedBox(height: 48),
                _buildActionButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(Color secondaryTextColor) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final kesEquivalent = amount * 130.0;

    return GlassCard(
      child: Column(
        children: [
          Text('Enter Amount (USD)', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (v) => setState(() {}),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none),
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ${CurrencyFormatter.format(kesEquivalent, 'KES')}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMpesaField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('M-Pesa Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: () => setState(() => _isAddingNew = !_isAddingNew),
              icon: Icon(_isAddingNew ? LucideIcons.user : LucideIcons.plus, size: 16),
              label: Text(_isAddingNew ? 'Use Primary' : 'Add New', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_isAddingNew && _currentUser?.phoneNumber != null)
          GestureDetector(
            onTap: () => setState(() => _isAddingNew = false),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Primary Number', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                      Text(_currentUser!.phoneNumber!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixText: '+254 ',
                  hintText: '7XXXXXXXX',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberNumber,
                    onChanged: (v) => setState(() => _rememberNumber = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Remember this number', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBankInfo(Color secondaryTextColor) {
    if (_isLoadingAccounts) return const Center(child: CircularProgressIndicator());
    if (_systemAccounts.isEmpty) return const Center(child: Text('No bank accounts available'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manual Bank Funding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Transfer funds to any of the accounts below and upload the receipt in the help section.', 
          style: TextStyle(color: secondaryTextColor, fontSize: 12)),
        const SizedBox(height: 24),
        ..._systemAccounts.map((acc) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(acc['bank_name'] ?? 'Bank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: acc['account_number'] ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account number copied')));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('A/C: ${acc['account_number']}', style: TextStyle(fontSize: 14, color: secondaryTextColor)),
                Text('Name: ${acc['account_holder_name']}', style: TextStyle(fontSize: 14, color: secondaryTextColor)),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActionButton() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final isLoading = state is TransactionInProgress || state is TransactionLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _onDeposit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Deposit with ${widget.method.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
