import 'dart:convert';
import 'dart:ui';
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TransactionService _txService = TransactionService();
  
  late String _selectedMethod;
  List<Map<String, dynamic>> _systemAccounts = [];
  String? _selectedBankName;
  String? _referenceCode;
  Map<String, dynamic>? _selectedBankToLink;
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  bool _isProcessing = false;
  String _processingMessage = 'Securing your connection...';
  VaultUser? _currentUser;
  List<BankAccount> _userAccounts = [];
  bool _isAddingNew = false;
  bool _rememberNumber = false;
  bool _isUsd = true;
  String _searchQuery = '';
  bool _isAwaitingMpesa = false;
  bool _isAwaitingPix = false;
  String? _pixBrCode;
  String? _pixBrCodeBase64;
  DateTime? _pixExpiresAt;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.method;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _txService.getSystemBankAccounts(),
        _txService.getCurrentUserProfile(),
      ]);
      
      _systemAccounts = results[0] as List<Map<String, dynamic>>;
      _currentUser = results[1] as VaultUser?;
      _referenceCode = _txService.generateReferenceCode();

      if (_currentUser?.phoneNumber != null) {
        _phoneController.text = _currentUser!.phoneNumber!;
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _onDeposit() {
    HapticFeedback.lightImpact();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedMethod == 'bank' && _selectedBankName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank from the list to proceed'), backgroundColor: Colors.orange),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinEntrySheet(
        onConfirm: (pin) {
          Navigator.pop(context);
          
          final walletCredit = _isUsd ? amount : amount / 130.0;
          final kesEquivalent = _isUsd ? amount * 130.0 : amount;

          if (_selectedMethod == 'mpesa') {
            final phoneNumber = _isAddingNew ? _phoneController.text : (_currentUser?.phoneNumber ?? _phoneController.text);
            context.read<TransactionBloc>().add(PerformMpesaDeposit(
              phoneNumber: phoneNumber,
              walletCredit: walletCredit,
              kesEquivalent: kesEquivalent,
              pin: pin,
            ));
          } else if (_selectedMethod == 'pix') {
            // PIX é sempre em BRL: usamos o valor digitado direto, sem
            // conversão USD/KES (essa conversão é específica da versão Kenya
            // do app). Ajuste aqui se/quando o app for 100% BRL.
            context.read<TransactionBloc>().add(PerformPixDeposit(
              amount: amount,
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

    return Stack(
      children: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) async {
            if (state is TransactionSuccess) {
              setState(() {
                _isProcessing = false;
                _isAwaitingPix = false; // fecha o QR quando o webhook confirma
              });

              if (state.message.contains('STK Push sent')) {
                 setState(() => _isAwaitingMpesa = true);
              } else {
                _showSuccessOverlay(state.message);
              }
            } else if (state is PixChargeCreated) {
              setState(() {
                _isAwaitingPix = true;
                _pixBrCode = state.brCode;
                _pixBrCodeBase64 = state.brCodeBase64;
                _pixExpiresAt = state.expiresAt;
              });
            } else if (state is TransactionError) {
              setState(() {
                _isProcessing = false;
                _isAwaitingMpesa = false;
                _isAwaitingPix = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            } else if (state is TransactionInProgress) {
              setState(() {
                _isProcessing = true;
                _processingMessage = state.message;
              });
            }
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Deposit Funds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  _buildMethodSegmentedControl(),
                  const SizedBox(height: 32),
                  _buildAmountInput(secondaryTextColor),
                  const SizedBox(height: 32),
                  if (_selectedMethod == 'mpesa') _buildMpesaField(isDark),
                  if (_selectedMethod == 'bank') _buildBankFlow(isDark, secondaryTextColor, primaryTextColor),
                  if (_selectedMethod == 'pix') _buildPixField(secondaryTextColor),
                  const SizedBox(height: 48),
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
        if (_isProcessing) _buildProcessingOverlay(),
        if (_isAwaitingMpesa) _buildMpesaWaitingOverlay(),
        if (_isAwaitingPix) _buildPixWaitingOverlay(),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.loader2, color: AppColors.primary, size: 40)
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 1.seconds),
              const SizedBox(height: 24),
              Text(
                _processingMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 48),
              TextButton.icon(
                onPressed: () => setState(() => _isProcessing = false),
                icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                label: const Text('Cancel & Return', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMpesaWaitingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPingingSmartphone(),
              const SizedBox(height: 32),
              const Text(
                'Waiting for M-Pesa PIN...',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your phone for the STK prompt',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => setState(() => _isAwaitingMpesa = false),
                child: const Text('Cancel & Close', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPingingSmartphone() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(3, (index) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .scale(begin: const Offset(1, 1), end: const Offset(2.5, 2.5), duration: 2.seconds, delay: (index * 600).ms)
           .fadeOut(duration: 2.seconds);
        }),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.smartphone, color: Colors.white, size: 40),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
      ],
    );
  }

  Widget _buildMethodSegmentedControl() {
    final methods = [
      {'id': 'mpesa', 'label': 'Mobile', 'icon': LucideIcons.phone},
      {'id': 'bank', 'label': 'Bank', 'icon': LucideIcons.landmark},
      {'id': 'pix', 'label': 'PIX', 'icon': LucideIcons.qrCode},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: methods.map((m) {
          final isSelected = _selectedMethod == m['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMethod = m['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
                    const SizedBox(width: 8),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmountInput(Color secondaryTextColor) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final exchangeRate = 130.0;
    final converted = _isUsd ? amount * exchangeRate : amount / exchangeRate;
    final settlementLabel = _isUsd ? 'KES' : 'USD';

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enter Amount', style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildCurrencyToggle('USD'),
                    _buildCurrencyToggle('KES'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (v) => setState(() {}),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: -1),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.3)),
              border: InputBorder.none,
              prefixText: _isUsd ? '\$ ' : 'KSh ',
              prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Settlement Amount: ', style: TextStyle(fontSize: 12, color: Colors.green)),
                Text(
                  CurrencyFormatter.format(converted, settlementLabel),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyToggle(String code) {
    final isSelected = (_isUsd && code == 'USD') || (!_isUsd && code == 'KES');
    return GestureDetector(
      onTap: () => setState(() => _isUsd = code == 'USD'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight)),
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
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
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

  Widget _buildPixField(Color secondaryTextColor) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.qrCode, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Um QR Code PIX será gerado com o valor acima. Aponte a câmera do seu banco ou copie o código.',
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixWaitingOverlay() {
    final imageBytes = _pixBrCodeBase64 != null ? base64Decode(_pixBrCodeBase64!) : null;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(imageBytes, width: 220, height: 220),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Aguardando pagamento PIX...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_pixExpiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expira às ${_pixExpiresAt!.hour.toString().padLeft(2, '0')}:${_pixExpiresAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _pixBrCode == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: _pixBrCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copia-e-cola copiado!')),
                          );
                        },
                  icon: const Icon(LucideIcons.copy, color: Colors.white, size: 16),
                  label: const Text('Copiar código PIX', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() => _isAwaitingPix = false),
                  child: const Text('Cancelar & Fechar', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankFlow(bool isDark, Color secondaryTextColor, Color primaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        _buildBankSearchGrid(isDark, secondaryTextColor),
        const SizedBox(height: 32),
        const Text('Manual Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildManualBankInfo(secondaryTextColor),
      ],
    );
  }

  Widget _buildBankSearchGrid(bool isDark, Color secondaryTextColor) {
    final banks = _txService.getSupportedBanks().where((b) => b['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search Kenyan Banks...',
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: banks.length,
          itemBuilder: (context, index) {
            final bank = banks[index];
            final isSelected = _selectedBankName == bank['name'];
            return InkWell(
              onTap: () {
                setState(() => _selectedBankName = bank['name']);
              },
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Center(child: Icon(LucideIcons.landmark, size: 14, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(bank['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSuccessOverlay(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 64).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text('Success!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
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
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt upload coming soon. Please keep your transaction message for manual verification.'), backgroundColor: AppColors.primary),
            );
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
          onPressed: isLoading ? null : () {
            _onDeposit();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Deposit with ${_selectedMethod.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
