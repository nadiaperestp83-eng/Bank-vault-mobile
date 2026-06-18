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
import 'p2p/qr_scanner_screen.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../../models/vault_models.dart';
import '../../../models/bill_split_model.dart';
import '../../../services/biometric_service.dart';
import '../../../services/storage_service.dart';

class TransactScreen extends StatefulWidget {
  final VaultUser? initialRecipient;
  const TransactScreen({super.key, this.initialRecipient});

  @override
  State<TransactScreen> createState() => _TransactScreenState();
}

class _TransactScreenState extends State<TransactScreen> {
  int _activeTab = 0; // 0: Send, 1: Deposit, 2: Withdraw, 3: Split
  String _selectedCurrency = 'KES';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  
  // Bill Split State
  final TextEditingController _splitTitleController = TextEditingController();
  final TextEditingController _splitAmountController = TextEditingController();
  final TextEditingController _splitSearchController = TextEditingController();
  List<VaultUser> _selectedParticipants = [];
  String _splitMethod = 'equal'; // 'equal' or 'custom'
  bool _includeCreator = true;
  Map<String, double> _customAmounts = {};
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Rent', 'Shopping', 'Entertainment', 'Utilities', 'Travel', 'General'];

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
    _splitTitleController.dispose();
    _splitAmountController.dispose();
    _splitSearchController.dispose();
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
            _toggleItem(3, 'Split', isDark),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
      case 3:
        return _buildSplitSection(isDark, surfaceColor, borderColor);
      default:
        return const SizedBox();
    }
  }

  // --- SPLIT SECTION ---
  Widget _buildSplitSection(bool isDark, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreateSplitButton(isDark, surfaceColor, borderColor),
        const SizedBox(height: 32),
        const Text('Owed to Me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildOwedToMeList(isDark, surfaceColor, borderColor),
        const SizedBox(height: 32),
        const Text('What I Owe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildWhatIOweList(isDark, surfaceColor, borderColor),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildCreateSplitButton(bool isDark, Color surfaceColor, Color borderColor) {
    return GestureDetector(
      onTap: () => _showCreateSplitDialog(isDark, surfaceColor, borderColor),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.users, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create New Bill Split', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Divide expenses with friends instantly', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOwedToMeList(bool isDark, Color surfaceColor, Color borderColor) {
    return StreamBuilder<List<BillSplit>>(
      stream: context.read<TransactionBloc>().transactionService.getOwedToMeStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final splits = snapshot.data ?? [];
        if (splits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Nobody owes you money yet', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: splits.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final split = splits[index];
            final paidCount = split.members.where((m) => m.status == 'paid').length;
            final totalCount = split.members.length;
            final progress = totalCount > 0 ? paidCount / totalCount : 0.0;

            return GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(split.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(CurrencyFormatter.format(split.totalAmount, 'KES'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.tag, size: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(split.category, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      const Spacer(),
                      Text('$paidCount/$totalCount paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  if (paidCount == 0) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.read<TransactionBloc>().add(CancelBillSplit(splitId: split.id));
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Cancel Split', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWhatIOweList(bool isDark, Color surfaceColor, Color borderColor) {
    return StreamBuilder<List<BillSplitMember>>(
      stream: context.read<TransactionBloc>().transactionService.getWhatIOweStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('You are all caught up!', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final member = members[index];
            return FutureBuilder<BillSplit?>(
              future: _fetchSplitDetails(member.splitId),
              builder: (context, splitSnapshot) {
                final split = splitSnapshot.data;
                if (split == null) return const SizedBox();

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      _buildCreatorAvatar(split.creatorProfile),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(split.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('From ${split.creatorProfile?.firstName ?? 'Friend'}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyFormatter.format(member.amount, 'KES'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _paySplitShare(member),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              minimumSize: const Size(60, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<BillSplit?> _fetchSplitDetails(String splitId) async {
    try {
      final response = await Supabase.instance.client
          .from('bill_splits')
          .select('*, creator:profiles(*)')
          .eq('id', splitId)
          .single();
      return BillSplit.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Widget _buildCreatorAvatar(VaultUser? creator) {
    if (creator == null) return const CircleAvatar(radius: 20, child: Icon(LucideIcons.user));
    final initials = (creator.firstName?[0] ?? '') + (creator.lastName?[0] ?? '');
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: creator.profilePhotoUrl != null ? NetworkImage(creator.profilePhotoUrl!) : null,
      child: creator.profilePhotoUrl == null ? Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)) : null,
    );
  }

  void _paySplitShare(BillSplitMember member) {
    _showPinSheet((pin) {
      context.read<TransactionBloc>().add(PayBillSplit(memberId: member.id, pin: pin));
    });
  }

  // --- CREATE SPLIT DIALOG ---
  void _showCreateSplitDialog(bool isDark, Color surfaceColor, Color borderColor) {
    setState(() {
      _splitTitleController.clear();
      _splitAmountController.clear();
      _selectedParticipants = [];
      _splitMethod = 'equal';
      _includeCreator = true;
      _customAmounts = {};
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Bill Split', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _splitTitleController,
                  decoration: InputDecoration(
                    labelText: 'What is this for?',
                    hintText: 'e.g. Dinner at Mama Rocks',
                    prefixIcon: const Icon(LucideIcons.edit3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _splitAmountController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Total Amount',
                    prefixIcon: const Icon(LucideIcons.banknote),
                    suffixText: 'KES',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (v) => setModalState(() => _selectedCategory = cat),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Participants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_selectedParticipants.length} added', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildUserSearch(isDark, borderColor, setModalState),
                const SizedBox(height: 16),
                _buildParticipantChips(setModalState),
                const SizedBox(height: 32),
                _buildSplitMethodToggle(isDark, surfaceColor, borderColor, setModalState),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _includeCreator,
                  onChanged: (v) => setModalState(() => _includeCreator = v ?? true),
                  title: const Text('Include myself in the split', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 24),
                _buildSplitBreakdown(isDark, setModalState),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _canCreateSplit() ? () => _handleCreateSplit() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create Split', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSearch(bool isDark, Color borderColor, StateSetter setModalState) {
    return Column(
      children: [
        TextField(
          controller: _splitSearchController,
          onChanged: (v) => setModalState(() {}),
          decoration: InputDecoration(
            hintText: 'Search friends by @tag',
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (_splitSearchController.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: FutureBuilder<List<VaultUser>>(
              future: context.read<TransactionBloc>().transactionService.searchUsers(_splitSearchController.text),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No users found', style: TextStyle(fontSize: 12)),
                  );
                }
                final results = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final user = results[index];
                    final isSelected = _selectedParticipants.any((u) => u.id == user.id);
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                        child: user.profilePhotoUrl == null ? Text(user.firstName?[0] ?? '?', style: const TextStyle(fontSize: 10)) : null,
                      ),
                      title: Text(user.kycTag ?? user.firstName ?? 'User', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(user.firstName ?? '', style: const TextStyle(fontSize: 11)),
                      trailing: Icon(
                        isSelected ? LucideIcons.checkCircle2 : LucideIcons.plusCircle,
                        color: isSelected ? AppColors.success : AppColors.primary,
                        size: 20,
                      ),
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            _selectedParticipants.removeWhere((u) => u.id == user.id);
                          } else {
                            _selectedParticipants.add(user);
                          }
                          _splitSearchController.clear();
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantChips(StateSetter setModalState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedParticipants.map((user) => Chip(
        label: Text(user.kycTag ?? user.firstName ?? 'User', style: const TextStyle(fontSize: 12)),
        onDeleted: () => setModalState(() => _selectedParticipants.removeWhere((u) => u.id == user.id)),
        deleteIcon: const Icon(LucideIcons.x, size: 14),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildSplitMethodToggle(bool isDark, Color surfaceColor, Color borderColor, StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _methodToggleItem('Equal', _splitMethod == 'equal', () => setModalState(() => _splitMethod = 'equal')),
          ),
          Expanded(
            child: _methodToggleItem('Custom', _splitMethod == 'custom', () => setModalState(() => _splitMethod = 'custom')),
          ),
        ],
      ),
    );
  }

  Widget _methodToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSplitBreakdown(bool isDark, StateSetter setModalState) {
    final total = double.tryParse(_splitAmountController.text) ?? 0.0;
    if (total <= 0) return const SizedBox();

    final count = _selectedParticipants.length + (_includeCreator ? 1 : 0);
    if (count == 0) return const SizedBox();

    if (_splitMethod == 'equal') {
      final share = total / count;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, color: AppColors.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Each person will pay ${CurrencyFormatter.format(share, 'KES')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_includeCreator) _buildCustomInput('You', (v) => _customAmounts['creator'] = v, setModalState),
          ..._selectedParticipants.map((u) => _buildCustomInput(u.kycTag ?? u.firstName ?? 'User', (v) => _customAmounts[u.id] = v, setModalState)),
          const SizedBox(height: 12),
          _buildTotalCheck(total),
        ],
      );
    }
  }

  Widget _buildCustomInput(String name, Function(double) onChanged, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 120,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: (v) {
                onChanged(double.tryParse(v) ?? 0.0);
                setModalState(() {});
              },
              decoration: const InputDecoration(
                suffixText: ' KES',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCheck(double total) {
    double currentSum = 0;
    _customAmounts.forEach((key, value) => currentSum += value);
    final diff = total - currentSum;
    final isMatch = diff.abs() < 0.01;

    return Text(
      isMatch ? 'Total matches!' : (diff > 0 ? 'Remaining: ${diff.toStringAsFixed(2)} KES' : 'Over: ${diff.abs().toStringAsFixed(2)} KES'),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isMatch ? AppColors.success : AppColors.error,
      ),
    );
  }

  bool _canCreateSplit() {
    final title = _splitTitleController.text;
    final total = double.tryParse(_splitAmountController.text) ?? 0.0;
    if (title.isEmpty || total <= 0 || _selectedParticipants.isEmpty) return false;

    if (_splitMethod == 'equal') return true;

    double currentSum = 0;
    _customAmounts.forEach((key, value) => currentSum += value);
    return (total - currentSum).abs() < 0.01;
  }

  void _handleCreateSplit() {
    final title = _splitTitleController.text;
    final total = double.tryParse(_splitAmountController.text) ?? 0.0;
    final count = _selectedParticipants.length + (_includeCreator ? 1 : 0);
    
    List<Map<String, dynamic>> members = [];
    double creatorAmount = 0;

    if (_splitMethod == 'equal') {
      final share = total / count;
      for (var u in _selectedParticipants) {
        members.add({'user_id': u.id, 'amount': share});
      }
      creatorAmount = share;
    } else {
      for (var u in _selectedParticipants) {
        members.add({'user_id': u.id, 'amount': _customAmounts[u.id] ?? 0.0});
      }
      creatorAmount = _customAmounts['creator'] ?? 0.0;
    }

    Navigator.pop(context);
    _showPinSheet((pin) {
      context.read<TransactionBloc>().add(CreateBillSplit(
        title: title,
        totalAmount: total,
        category: _selectedCategory,
        members: members,
        creatorAmount: creatorAmount,
        pin: pin,
      ));
    });
  }

  // --- SEND SECTION ---
  Widget _buildSendSection(bool isDark, Color surfaceColor, Color borderColor) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        List<VaultUser> recipients = [];
        if (state is RecipientsLoaded) {
          recipients = List.from(state.searchResults.isNotEmpty ? state.searchResults : state.frequent);
          
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
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
