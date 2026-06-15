import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/services/transaction_service.dart';
import 'withdrawal_confirmation_screen.dart';

class WithdrawalSetupScreen extends StatefulWidget {
  final double amount;
  const WithdrawalSetupScreen({super.key, required this.amount});

  @override
  State<WithdrawalSetupScreen> createState() => _WithdrawalSetupScreenState();
}

class _WithdrawalSetupScreenState extends State<WithdrawalSetupScreen> {
  String _channel = 'bank'; // 'bank' or 'mobile'
  String? _selectedProvider;
  String? _selectedRecipientId;
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  final List<Map<String, String>> _banks = [
    {'name': 'KCB Bank', 'id': 'kcb'},
    {'name': 'Equity Bank', 'id': 'equity'},
    {'name': 'Co-operative Bank', 'id': 'coop'},
    {'name': 'Absa Bank', 'id': 'absa'},
    {'name': 'NCBA Bank', 'id': 'ncba'},
    {'name': 'Stanbic Bank', 'id': 'stanbic'},
    {'name': 'Standard Chartered', 'id': 'standard-chartered'},
  ];

  final List<Map<String, String>> _mobileProviders = [
    {'name': 'M-Pesa', 'id': 'mpesa'},
    {'name': 'Airtel Money', 'id': 'airtel'},
  ];

  List<Map<String, dynamic>> _savedRecipients = [];
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _transactionService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _savedRecipients = [
            {
              'id': 'primary',
              'name': 'Primary Line',
              'number': profile.phoneNumber ?? '+254700000000',
              'provider': 'mpesa',
              'isPrimary': true,
            },
            {
              'id': 'secondary',
              'name': 'Secondary (Home)',
              'number': '+254712345678',
              'provider': 'airtel',
              'isPrimary': false,
            },
          ];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^\+254[17]\d{8}$|^0[17]\d{8}$|^[17]\d{8}$');
    return regex.hasMatch(phone);
  }

  void _onNext() {
    final Map<String, dynamic> details = {
      'channel': _channel,
    };

    String description = '';
    if (_channel == 'bank') {
      if (_selectedProvider == null || _accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) return;
      details['provider'] = _selectedProvider;
      details['accountNumber'] = _accountNumberController.text;
      details['accountName'] = _accountNameController.text;
      final bankName = _banks.firstWhere((b) => b['id'] == _selectedProvider)['name'];
      description = 'Withdrawal to $bankName (A/C: ${_accountNumberController.text})';
    } else {
      if (_selectedRecipientId != null && _selectedRecipientId != 'new') {
        final recipient = _savedRecipients.firstWhere((r) => r['id'] == _selectedRecipientId);
        details['provider'] = recipient['provider'];
        details['phoneNumber'] = recipient['number'];
        final providerName = _mobileProviders.firstWhere((p) => p['id'] == recipient['provider'])['name'];
        description = 'Withdrawal to $providerName (${recipient['number']})';
      } else {
        if (_selectedProvider == null || !_isValidPhone(_phoneController.text)) return;
        details['provider'] = _selectedProvider;
        details['phoneNumber'] = _phoneController.text;
        final providerName = _mobileProviders.firstWhere((p) => p['id'] == _selectedProvider)['name'];
        description = 'Withdrawal to $providerName (${_phoneController.text})';
      }
    }
    details['description'] = description;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalConfirmationScreen(
          details: details,
          amount: widget.amount,
        ),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bank & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            const Text('Choose Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildChannelSelector(isDark, surfaceColor, borderColor),
            const SizedBox(height: 32),
            const Text('Destination Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (_channel == 'bank') 
              _buildBankForm(secondaryTextColor, surfaceColor, borderColor) 
            else 
              _buildMobileForm(secondaryTextColor, surfaceColor, borderColor),
            const SizedBox(height: 48),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSelector(bool isDark, Color surfaceColor, Color borderColor) {
    return Row(
      children: [
        _channelChip('Bank Account', 'bank', LucideIcons.building, isDark, surfaceColor, borderColor),
        const SizedBox(width: 12),
        _channelChip('Mobile Money', 'mobile', LucideIcons.smartphone, isDark, surfaceColor, borderColor),
      ],
    );
  }

  Widget _channelChip(String label, String value, IconData icon, bool isDark, Color surfaceColor, Color borderColor) {
    bool isSelected = _channel == value;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _channel = value;
          _selectedProvider = null;
          _selectedRecipientId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : secondaryTextColor, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankForm(Color secondaryTextColor, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Select Bank',
          value: _selectedProvider,
          items: _banks.map((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']!))).toList(),
          onChanged: (v) => setState(() => _selectedProvider = v),
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Account Number',
          controller: _accountNumberController,
          hint: 'Enter bank account number',
          keyboardType: TextInputType.number,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Account Holder Name',
          controller: _accountNameController,
          hint: 'Enter name as it appears on bank',
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildMobileForm(Color secondaryTextColor, Color surfaceColor, Color borderColor) {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saved Recipients', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        ..._savedRecipients.map((r) => _buildRecipientCard(r, surfaceColor, borderColor)),
        _buildRecipientCard({
          'id': 'new',
          'name': 'Add New Number',
          'number': 'Enter manually',
          'provider': null,
        }, surfaceColor, borderColor),
        if (_selectedRecipientId == 'new') ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Select Provider',
            value: _selectedProvider,
            items: _mobileProviders.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!))).toList(),
            onChanged: (v) => setState(() => _selectedProvider = v),
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: '+254...',
            keyboardType: TextInputType.phone,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            errorText: _phoneController.text.isNotEmpty && !_isValidPhone(_phoneController.text) ? 'Invalid +254 number' : null,
          ),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildRecipientCard(Map<String, dynamic> recipient, Color surfaceColor, Color borderColor) {
    bool isSelected = _selectedRecipientId == recipient['id'];
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRecipientId = recipient['id'];
        if (_selectedRecipientId != 'new') {
          _selectedProvider = recipient['provider'];
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                recipient['id'] == 'new' ? LucideIcons.plus : LucideIcons.user,
                color: isSelected ? Colors.white : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipient['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(recipient['number'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              hint: const Text('Select option', style: TextStyle(color: Colors.grey, fontSize: 14)),
              icon: const Icon(LucideIcons.chevronDown, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: surfaceColor,
            errorText: errorText,
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
      ],
    );
  }

  Widget _buildNextButton() {
    bool isValid = false;
    if (_channel == 'bank') {
      isValid = _selectedProvider != null && _accountNumberController.text.isNotEmpty && _accountNameController.text.isNotEmpty;
    } else {
      if (_selectedRecipientId != null && _selectedRecipientId != 'new') {
        isValid = true;
      } else {
        isValid = _selectedProvider != null && _isValidPhone(_phoneController.text);
      }
    }

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
      child: const Text('Review Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
