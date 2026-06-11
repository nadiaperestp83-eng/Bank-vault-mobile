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
  final TextEditingController _accountNumberController = TextEditingController();
  final TransactionService _txService = TransactionService();
  List<BankAccount> _userAccounts = [];
  List<Map<String, dynamic>> _systemAccounts = [];
  BankAccount? _selectedAccount;
  String? _referenceCode;
  bool _isLoadingAccounts = false;
  VaultUser? _currentUser;
  bool _isAddingNew = false;
  bool _rememberNumber = false;
  Map<String, String>? _selectedBankToLink;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingAccounts = true);
    try {
      if (widget.method == 'bank') {
        _userAccounts = await _txService.getUserBankAccounts();
        _systemAccounts = await _txService.getSystemBankAccounts();
        _referenceCode = _txService.generateReferenceCode();
      }
      _currentUser = await _txService.getCurrentUserProfile();
      if (_currentUser?.phoneNumber != null) {
        _phoneController.text = _currentUser!.phoneNumber!;
      }
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _showBankSelectionSheet() {
    final banks = _txService.getSupportedBanks();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: banks.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(LucideIcons.landmark, color: AppColors.primary, size: 20),
                    ),
                    title: Text(bank['name']!),
                    onTap: () {
                      setState(() => _selectedBankToLink = bank);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLinkBank() async {
    if (_selectedBankToLink == null || _accountNumberController.text.isEmpty) return;
    
    setState(() => _isLoadingAccounts = true);
    try {
      await _txService.linkBankAccount(
        bankName: _selectedBankToLink!['name']!,
        accountNumber: _accountNumberController.text,
      );
      _userAccounts = await _txService.getUserBankAccounts();
      setState(() => _selectedBankToLink = null);
      _accountNumberController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank account linked successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingAccounts = false);
    }
  }

  void _onDeposit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    if (widget.method == 'bank' && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or link a bank account'), backgroundColor: Colors.red),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(
        onConfirm: (pin) async {
          final isPinValid = await _txService.verifyPin(pin);
          if (!isPinValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid Transaction PIN'), backgroundColor: Colors.red),
            );
            return;
          }

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
          } else if (widget.method == 'bank') {
            if (_selectedAccount?.stripeBankAccountId != null) {
              // Stripe ACH Flow
              await _txService.createStripeAchIntent(amount: amount, currency: 'USD');
              if (mounted) Navigator.pop(context);
            } else {
              // Manual Bank Transfer logic would normally go here or via "I have sent" button
            }
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
              _buildAmountInput(secondaryTextColor),
              const SizedBox(height: 32),
              if (widget.method == 'mpesa') _buildMpesaField(isDark),
              if (widget.method == 'bank') _buildBankFlow(isDark, secondaryTextColor, primaryTextColor),
              const SizedBox(height: 48),
              _buildActionButton(),
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

  Widget _buildBankFlow(bool isDark, Color secondaryTextColor, Color primaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedBankToLink != null) ...[
          Text('Linking ${_selectedBankToLink!['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Account Number',
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _selectedBankToLink = null),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onLinkBank,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Link Account'),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text('Select Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          if (_userAccounts.isEmpty)
            GestureDetector(
              onTap: _showBankSelectionSheet,
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.landmark, color: secondaryTextColor, size: 32),
                      const SizedBox(height: 12),
                      const Text('No Bank Accounts Linked', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Link an account for instant ACH deposits', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _showBankSelectionSheet, child: const Text('Link New Bank')),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                ..._userAccounts.map((acc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAccount = acc),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      border: _selectedAccount?.id == acc.id ? Border.all(color: AppColors.primary, width: 2) : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.landmark, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('****${acc.accountNumber.substring(acc.accountNumber.length - 4)}', 
                                style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          if (_selectedAccount?.id == acc.id)
                            const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
                TextButton.icon(
                  onPressed: _showBankSelectionSheet,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Link Another Bank'),
                ),
              ],
            ),
        ],
        
        const SizedBox(height: 32),
        const Text('Manual Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildManualBankInfo(secondaryTextColor),
      ],
    );
  }

  Widget _buildManualBankInfo(Color secondaryTextColor) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Send funds to our account:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              ..._systemAccounts.take(1).map((acc) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(acc['bank_name'] ?? 'Bank', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 16),
                        onPressed: () => Clipboard.setData(ClipboardData(text: acc['account_number'] ?? '')),
                      ),
                    ],
                  ),
                  Text('A/C: ${acc['account_number']}', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                ],
              )),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text('2. Use this reference code:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_referenceCode ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2)),
                    const Icon(LucideIcons.info, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // Logic to pick image and upload receipt
          },
          icon: const Icon(LucideIcons.upload, size: 18),
          label: const Text('I have sent the funds (Upload Receipt)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
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
