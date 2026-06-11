import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'deposit/deposit_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/pin_entry_sheet.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/utils/logo_mapper.dart';
import 'package:vault_os/src/services/dashboard_service.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../../models/vault_models.dart';

class TransactScreen extends StatefulWidget {
  const TransactScreen({super.key});

  @override
  State<TransactScreen> createState() => _TransactScreenState();
}

class _TransactScreenState extends State<TransactScreen> {
  int _activeTab = 0; // 0: Send, 1: Deposit, 2: Withdraw
  String _selectedCurrency = 'KES';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  VaultUser? _selectedRecipient;
  final DashboardService _dashboardService = DashboardService();
  Wallet? _currentWallet;
  StreamSubscription? _walletSubscription;

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadFrequentRecipients());
    _walletSubscription = _dashboardService.getWalletStream().listen((wallet) {
      if (mounted) setState(() => _currentWallet = wallet);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _recipientController.dispose();
    _walletSubscription?.cancel();
    super.dispose();
  }

  void _showPinSheet(Function(String) onConfirm) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(onConfirm: onConfirm),
    );
  }

  void _handleTransaction() {
    HapticFeedback.lightImpact();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    _showPinSheet((pin) async {
      if (_activeTab == 0) {
        if (_selectedRecipient == null) return;
        context.read<TransactionBloc>().add(PerformVaultTransfer(
          recipientTag: _selectedRecipient!.kycTag!,
          amount: amount,
          currency: _selectedCurrency,
          pin: pin,
        ));
      } else if (_activeTab == 1) {
        // Deposit logic: M-Pesa is default for now in the tab
        context.read<TransactionBloc>().add(PerformMpesaDeposit(
          phoneNumber: _phoneController.text,
          amount: amount,
          pin: pin,
        ));
      } else if (_activeTab == 2) {
        context.read<TransactionBloc>().add(PerformWithdrawal(
          amount: amount,
          method: 'bank',
          currency: _selectedCurrency,
          description: 'Withdrawal to Bank',
          details: {},
          pin: pin,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) async {
        if (state is TransactionSuccess) {
          if (state.message.contains('Stripe')) {
            // Handle Stripe Payment Sheet
            try {
              await Stripe.instance.initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: state.transactionId!,
                  merchantDisplayName: 'Vault OS',
                ),
              );
              await Stripe.instance.presentPaymentSheet();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment Cancelled/Failed: $e'), backgroundColor: Colors.red),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          _amountController.clear();
          _phoneController.clear();
          _recipientController.clear();
          setState(() => _selectedRecipient = null);
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64), // Space for VaultTopNav
                _buildModeToggle(),
                const SizedBox(height: 32),
                _buildActiveSection(),
                const SizedBox(height: 40),
                _buildTransactionHistory(),
                const SizedBox(height: 100), // Space for bottom dock
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(6),
        borderRadius: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleItem(0, 'Send'),
            _toggleItem(1, 'Deposit'),
            _toggleItem(2, 'Withdraw'),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(int index, String label) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeTab) {
      case 0:
        return _buildSendSection();
      case 1:
        return _buildDepositSection();
      case 2:
        return _buildWithdrawSection();
      default:
        return const SizedBox();
    }
  }

  // --- SEND SECTION ---
  Widget _buildSendSection() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        List<VaultUser> recipients = [];
        if (state is RecipientsLoaded) {
          recipients = state.searchResults.isNotEmpty ? state.searchResults : state.frequent;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/transact/p2p'),
                  child: _buildProviderCard(LucideIcons.user, 'Vault User', true),
                ),
                const SizedBox(width: 12),
                _buildProviderCard(LucideIcons.landmark, 'Bank', false),
                const SizedBox(width: 12),
                _buildProviderCard(LucideIcons.smartphone, 'Mobile Money', false),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_recipientController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _recipientController.clear();
                      context.read<TransactionBloc>().add(LoadFrequentRecipients());
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientController,
              onChanged: (v) => context.read<TransactionBloc>().add(SearchRecipients(v)),
              decoration: InputDecoration(
                hintText: 'Search by @username or name',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipients.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildContactAvatar('Add', null, isAdd: true);
                  final user = recipients[index - 1];
                  final isSelected = _selectedRecipient?.id == user.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRecipient = user),
                    child: _buildContactAvatar(
                      user.firstName ?? user.kycTag ?? 'User',
                      (user.firstName?[0] ?? '') + (user.lastName?[0] ?? ''),
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildAmountCard('Send Amount'),
            const SizedBox(height: 32),
            _buildActionBtn('Send Now'),
          ],
        );
      },
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildProviderCard(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar(String name, String? initials, {bool isAdd = false, bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isAdd ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              child: isAdd 
                  ? const Icon(LucideIcons.plus, color: AppColors.primary)
                  : Text(initials ?? '??', style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- DEPOSIT SECTION ---
  Widget _buildDepositSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Funding Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildDepositCard(LucideIcons.smartphone, 'M-Pesa', () => _navigateToDeposit('mpesa')),
            const SizedBox(width: 12),
            _buildDepositCard(LucideIcons.creditCard, 'Card', () => _navigateToDeposit('card')),
            const SizedBox(width: 12),
            _buildDepositCard(LucideIcons.landmark, 'Bank', () => _navigateToDeposit('bank')),
          ],
        ),
        const SizedBox(height: 40),
        const Text('Funding History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('No recent funding actions', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildDepositCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: GlassCard(
          height: 100,
          padding: const EdgeInsets.all(12),
          borderRadius: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDeposit(String method) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DepositSetupScreen(method: method)),
    );
  }

  // --- WITHDRAW SECTION ---
  Widget _buildWithdrawSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go('/transact/withdraw'),
          child: _buildChannelSelector(),
        ),
        const SizedBox(height: 32),
        _buildAmountCard('Withdraw Amount'),
        const SizedBox(height: 32),
        _buildSummaryFees(),
        const SizedBox(height: 32),
        _buildActionBtn('Confirm Withdrawal'),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildChannelSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.building, color: AppColors.textSecondaryLight, size: 20),
          SizedBox(width: 12),
          Text('Select Bank / Account', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
          Spacer(),
          Icon(LucideIcons.chevronDown, color: AppColors.textSecondaryLight, size: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryFees() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fee = amount * 0.01; // 1%
    final total = amount + fee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _summaryRow('Withdrawal Amount', CurrencyFormatter.format(amount, _selectedCurrency)),
          const SizedBox(height: 12),
          _summaryRow('Platform Fee', CurrencyFormatter.format(fee, _selectedCurrency), isRed: true),
          const Divider(height: 32),
          _summaryRow('Total Deduction', CurrencyFormatter.format(total, _selectedCurrency), isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isRed = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isRed ? Colors.red : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // --- SHARED WIDGETS ---
  Widget _buildAmountCard(String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              Text('Balance: ${CurrencyFormatter.format(_currentWallet?.balance ?? 0.0, _currentWallet?.currency ?? 'KES')}', 
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCurrency = _selectedCurrency == 'KES' ? 'USD' : 'KES'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedCurrency, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final isLoading = state is TransactionLoading || state is TransactionInProgress;
        return ElevatedButton(
          onPressed: isLoading ? null : _handleTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 10,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }

  Widget _buildTransactionHistory() {
    return FutureBuilder<List<VaultTransaction>>(
      future: context.read<TransactionBloc>().transactionService.getTransactionHistory(),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Icon(LucideIcons.search, size: 18, color: Colors.black.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 24),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (transactions.isEmpty)
              const Center(child: Text('No transactions yet'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 32, thickness: 0.5),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isDebit = tx.type == 'transfer' || tx.type == 'withdrawal';
                  
                  return Row(
                    children: [
                      LogoMapper.getLogo(tx.method, tx.description),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.description ?? 'Vault Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${tx.createdAt.day}/${tx.createdAt.month} ${tx.createdAt.hour}:${tx.createdAt.minute.toString().padLeft(2, '0')}', 
                              style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isDebit ? '-' : '+'} ${CurrencyFormatter.format(tx.amount, tx.currency)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDebit ? Colors.red : Colors.green,
                            ),
                          ),
                          if (tx.recordedBalance != null)
                            Text(CurrencyFormatter.format(tx.recordedBalance!, tx.currency), 
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Transfers', 'Deposits', 'Withdrawals'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          bool isSelected = f == 'All';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (v) {},
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.black.withValues(alpha: 0.05)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
