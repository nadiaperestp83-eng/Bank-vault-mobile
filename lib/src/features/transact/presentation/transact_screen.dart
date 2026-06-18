import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vault_os/src/common_widgets/kyc_verification_dialog.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'deposit/deposit_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import '../../../common_widgets/amount_entry_dialog.dart';
import '../../../common_widgets/pin_entry_sheet.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/utils/logo_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/transaction_service.dart';
import 'p2p/qr_scanner_screen.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../../models/vault_models.dart';

import '../../../services/biometric_service.dart';
import '../../../services/storage_service.dart';

class TransactScreen extends StatefulWidget {
  final VaultUser? initialRecipient;
  const TransactScreen({super.key, this.initialRecipient});

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
  final BiometricService _biometricService = BiometricService();
  final StorageService _storageService = StorageService();
  Wallet? _currentWallet;
  StreamSubscription? _walletSubscription;

  @override
  void initState() {
    super.initState();
    _selectedRecipient = widget.initialRecipient;
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

  void _handleTransaction() async {
    HapticFeedback.lightImpact();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    // For Vault transfers (Tab 0), try biometrics first if enabled
    if (_activeTab == 0 && _selectedRecipient != null) {
      final isBiometricAvailable = await _biometricService.isBiometricAvailable();
      final isBiometricEnabled = await _storageService.isBiometricEnabled();

      if (isBiometricAvailable && isBiometricEnabled) {
        final authenticated = await _biometricService.authenticate(
          reason: 'Authenticate to send $_selectedCurrency $amount to ${_selectedRecipient!.firstName ?? _selectedRecipient!.kycTag}',
        );

        if (authenticated) {
          final credentials = await _storageService.getCredentials();
          final storedPin = credentials['pin'];

          if (storedPin != null) {
            if (mounted) {
              context.read<TransactionBloc>().add(PerformVaultTransfer(
                recipientTag: _selectedRecipient!.kycTag!,
                amount: amount,
                currency: _selectedCurrency,
                pin: storedPin,
              ));
            }
            return;
          }
        }
      }
    }

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
        final walletCredit = _selectedCurrency == 'USD' ? amount : amount / 130.0;
        final kesEquivalent = _selectedCurrency == 'KES' ? amount : amount * 130.0;
        context.read<TransactionBloc>().add(PerformMpesaDeposit(
          phoneNumber: _phoneController.text,
          walletCredit: walletCredit,
          kesEquivalent: kesEquivalent,
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

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QrScannerScreen()),
    );

    if (result != null && result is Map<String, String>) {
      _handleScanResult(result);
    }
  }

  void _handleScanResult(Map<String, String> result) async {
    final txService = context.read<TransactionBloc>().transactionService;
    try {
      // Check KYC status first
      final profile = await txService.getCurrentUserProfile();
      if (profile == null || profile.kycStatus != 'verified') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => const KycVerificationDialog(),
          );
        }
        return;
      }

      VaultUser? user;
      if (result['type'] == 'id') {
        user = await txService.getUserById(result['value']!);
      } else if (result['type'] == 'tag') {
        user = await txService.getUserByTag(result['value']!);
      }

      if (user != null && mounted) {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          builder: (context) => AmountEntryDialog(
            recipient: user!,
            onConfirm: (amount, currency) {
              setState(() {
                _selectedRecipient = user;
                _activeTab = 0;
                _amountController.text = amount.toString();
                _selectedCurrency = currency;
              });
              // Automatically trigger transaction
              _handleTransaction();
            },
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) async {
        if (state is TransactionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
          _amountController.clear();
          _phoneController.clear();
          _recipientController.clear();
          setState(() => _selectedRecipient = null);
          
          // Navigate to home after a brief delay to let the snackbar be seen
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) context.go('/');
          });
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is KycRequiredState) {
          showDialog(
            context: context,
            builder: (_) => const KycVerificationDialog(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64), // Space for VaultTopNav
                _buildModeToggle(isDark, surfaceColor),
                const SizedBox(height: 32),
                _buildActiveSection(isDark, surfaceColor, borderColor),
                const SizedBox(height: 40),
                _buildTransactionHistory(isDark, borderColor),
                const SizedBox(height: 100), // Space for bottom dock
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isDark, Color surfaceColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleItem(0, 'Send', isDark),
            _toggleItem(1, 'Deposit', isDark),
            _toggleItem(2, 'Withdraw', isDark),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(int index, String label, bool isDark) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(bool isDark, Color surfaceColor, Color borderColor) {
    switch (_activeTab) {
      case 0:
        return _buildSendSection(isDark, surfaceColor, borderColor);
      case 1:
        return _buildDepositSection(isDark, surfaceColor, borderColor);
      case 2:
        return _buildWithdrawSection(isDark, surfaceColor, borderColor);
      default:
        return const SizedBox();
    }
  }

  // --- SEND SECTION ---
  Widget _buildSendSection(bool isDark, Color surfaceColor, Color borderColor) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        List<VaultUser> recipients = [];
        if (state is RecipientsLoaded) {
          recipients = List.from(state.searchResults.isNotEmpty ? state.searchResults : state.frequent);
          
          // Ensure _selectedRecipient is in the list if it exists
          if (_selectedRecipient != null) {
            final exists = recipients.any((r) => r.id == _selectedRecipient!.id);
            if (!exists) {
              recipients.insert(0, _selectedRecipient!);
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProviderCard(LucideIcons.user, 'Vault', true, isDark, surfaceColor, borderColor, () => context.go('/transact/p2p')),
                const SizedBox(width: 12),
                _buildProviderCard(LucideIcons.landmark, 'Bank', false, isDark, surfaceColor, borderColor, () {
                  HapticFeedback.selectionClick();
                  context.go('/transact/withdraw');
                }),
                const SizedBox(width: 12),
                _buildProviderCard(LucideIcons.smartphone, 'Mobile', false, isDark, surfaceColor, borderColor, () {
                  HapticFeedback.selectionClick();
                  context.go('/transact/withdraw');
                }),
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
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.scan, size: 20, color: AppColors.primary),
                  onPressed: _openScanner,
                ),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recipients.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildContactAvatar('Add', null, null, isDark, isAdd: true);
                  final user = recipients[index - 1];
                  final isSelected = _selectedRecipient?.id == user.id;
                  
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRecipient = user);
                    },
                    child: _buildContactAvatar(
                      user.firstName ?? user.kycTag ?? 'User',
                      (user.firstName?[0] ?? '') + (user.lastName?[0] ?? ''),
                      user.profilePhotoUrl,
                      isDark,
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildAmountCard('Send Amount', isDark, surfaceColor, borderColor),
            const SizedBox(height: 32),
            _buildActionBtn('Send Now'),
          ],
        );
      },
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildProviderCard(IconData icon, String label, bool isSelected, bool isDark, Color surfaceColor, Color borderColor, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), 
                  size: 24
                ),
                const SizedBox(height: 10),
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(String name, String? initials, String? profilePhotoUrl, bool isDark, {bool isAdd = false, bool isSelected = false}) {
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
              backgroundColor: isAdd ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
              backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                  ? NetworkImage(profilePhotoUrl)
                  : null,
              child: isAdd 
                  ? const Icon(LucideIcons.plus, color: AppColors.primary)
                  : (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                      ? Text(initials ?? '??', style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontWeight: FontWeight.bold))
                      : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- DEPOSIT SECTION ---
  Widget _buildDepositSection(bool isDark, Color surfaceColor, Color borderColor) {
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No recent funding actions', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12)),
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
  Widget _buildWithdrawSection(bool isDark, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go('/transact/withdraw'),
          child: _buildChannelSelector(isDark, surfaceColor, borderColor),
        ),
        const SizedBox(height: 32),
        _buildAmountCard('Withdraw Amount', isDark, surfaceColor, borderColor),
        const SizedBox(height: 32),
        _buildSummaryFees(isDark, surfaceColor, borderColor),
        const SizedBox(height: 32),
        _buildActionBtn('Confirm Withdrawal'),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildChannelSelector(bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.building, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 20),
          const SizedBox(width: 12),
          Text('Select Bank / Account', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14)),
          const Spacer(),
          Icon(LucideIcons.chevronDown, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryFees(bool isDark, Color surfaceColor, Color borderColor) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fee = amount * 0.01; // 1%
    final total = amount + fee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _summaryRow('Withdrawal Amount', CurrencyFormatter.format(amount, _selectedCurrency), isDark),
          const SizedBox(height: 12),
          _summaryRow('Platform Fee', CurrencyFormatter.format(fee, _selectedCurrency), isDark, isRed: true),
          const Divider(height: 32),
          _summaryRow('Total Deduction', CurrencyFormatter.format(total, _selectedCurrency), isDark, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {bool isRed = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isRed ? AppColors.error : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  // --- SHARED WIDGETS ---
  Widget _buildAmountCard(String label, bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13)),
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.5)),
                  ),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
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

  String _getTransactionTitle(VaultTransaction tx) {
    String title = tx.description ?? 'Vault Transaction';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (tx.type == 'transfer') {
      final otherProfile = tx.senderId == currentUserId ? tx.receiverProfile : tx.senderProfile;
      if (otherProfile != null) {
        final name = otherProfile.firstName ?? otherProfile.kycTag ?? 'User';
        title = '$title ($name)';
      }
    }
    return title;
  }

  Widget _buildTransactionIcon(VaultTransaction tx, bool isDebit, bool isDark) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isTransfer = tx.type == 'transfer';
    
    if (isTransfer) {
      final otherProfile = tx.senderId == currentUserId ? tx.receiverProfile : tx.senderProfile;
      if (otherProfile != null) {
        final profilePhotoUrl = otherProfile.profilePhotoUrl;
        final initials = ((otherProfile.firstName?.isNotEmpty ?? false) ? otherProfile.firstName![0] : '') + 
                        ((otherProfile.lastName?.isNotEmpty ?? false) ? otherProfile.lastName![0] : '');
        
        return CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
          child: profilePhotoUrl == null ? Text(
            initials,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
          ) : null,
        );
      }
    }
    
    return LogoMapper.getLogo(tx.method, tx.description);
  }

  Widget _buildTransactionHistory(bool isDark, Color borderColor) {
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
                Icon(LucideIcons.search, size: 18, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilters(isDark, borderColor),
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
                      _buildTransactionIcon(tx, isDebit, isDark),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getTransactionTitle(tx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${tx.createdAt.day}/${tx.createdAt.month} ${tx.createdAt.hour}:${tx.createdAt.minute.toString().padLeft(2, '0')}', 
                              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)
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
                            color: isDebit ? AppColors.error : AppColors.success,
                          ),
                          ),
                          if (tx.recordedBalance != null)
                            Text(CurrencyFormatter.format(tx.recordedBalance!, tx.currency), 
                              style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
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

  Widget _buildFilters(bool isDark, Color borderColor) {
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
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : borderColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
