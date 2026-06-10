import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_selectedProvider == null) return;
    
    final Map<String, dynamic> details = {
      'channel': _channel,
      'provider': _selectedProvider,
    };

    String description = '';
    if (_channel == 'bank') {
      if (_accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) return;
      details['accountNumber'] = _accountNumberController.text;
      details['accountName'] = _accountNameController.text;
      final bankName = _banks.firstWhere((b) => b['id'] == _selectedProvider)['name'];
      description = 'Withdrawal to $bankName (A/C: ${_accountNumberController.text})';
    } else {
      if (_phoneController.text.isEmpty) return;
      details['phoneNumber'] = _phoneController.text;
      final providerName = _mobileProviders.firstWhere((p) => p['id'] == _selectedProvider)['name'];
      description = 'Withdrawal to $providerName (${_phoneController.text})';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Bank & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimaryLight),
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
            _buildChannelSelector(),
            const SizedBox(height: 32),
            const Text('Destination Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (_channel == 'bank') _buildBankForm() else _buildMobileForm(),
            const SizedBox(height: 48),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSelector() {
    return Row(
      children: [
        _channelChip('Bank Account', 'bank', LucideIcons.building),
        const SizedBox(width: 12),
        _channelChip('Mobile Money', 'mobile', LucideIcons.smartphone),
      ],
    );
  }

  Widget _channelChip(String label, String value, IconData icon) {
    bool isSelected = _channel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _channel = value;
          _selectedProvider = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondaryLight, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondaryLight,
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

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Select Bank',
          value: _selectedProvider,
          items: _banks.map((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']!))).toList(),
          onChanged: (v) => setState(() => _selectedProvider = v),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Account Number',
          controller: _accountNumberController,
          hint: 'Enter bank account number',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Account Holder Name',
          controller: _accountNameController,
          hint: 'Enter name as it appears on bank',
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildMobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Select Provider',
          value: _selectedProvider,
          items: _mobileProviders.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!))).toList(),
          onChanged: (v) => setState(() => _selectedProvider = v),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Phone Number',
          controller: _phoneController,
          hint: 'Enter mobile number',
          keyboardType: TextInputType.phone,
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              hint: const Text('Select bank', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
      ],
    );
  }

  Widget _buildNextButton() {
    bool isValid = _selectedProvider != null && 
        (_channel == 'bank' ? (_accountNumberController.text.isNotEmpty && _accountNameController.text.isNotEmpty) : _phoneController.text.isNotEmpty);

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
