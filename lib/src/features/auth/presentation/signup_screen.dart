import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/common_widgets/vault_top_nav.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0; // 0: Account Details, 1: Email Verification, 2: KYC/Success
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String _selectedCountry = 'Kenya';

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinPart1Controller = TextEditingController();
  final _pinPart2Controller = TextEditingController();
  final _otpController = TextEditingController();

  final List<String> _countries = ['Kenya', 'US', 'UK', 'Nigeria', 'South Africa'];

  void _handleSendCode() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
    }
  }

  void _handleVerify() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VaultTopNav(),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackground.withOpacity(0.8),
              AppColors.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(AppSizes.p24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepper(),
                          const SizedBox(height: AppSizes.p24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: _buildCurrentStep(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildSuccessStep();
      default:
        return _buildStepOne();
    }
  }

  Widget _buildStepOne() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Your Vault Account',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'your unique identity',
          icon: LucideIcons.user,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'email for verification',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'for notifications',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildCountrySelector(),
        const SizedBox(height: AppSizes.p16),
        _buildPinSetup(),
        const SizedBox(height: AppSizes.p24),
        _buildLegalAgreement(),
        const SizedBox(height: AppSizes.p24),
        _buildActionButton(
          text: _isLoading ? 'Sending code...' : 'Send code',
          onPressed: _isLoading ? null : _handleSendCode,
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(LucideIcons.mailCheck, color: AppColors.primary, size: 48),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'We\'ve sent a 6-digit code to ${_emailController.text}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        _buildOtpInput(),
        const SizedBox(height: AppSizes.p24),
        _buildActionButton(
          text: _isLoading ? 'Verifying...' : 'Verify and continue',
          onPressed: _isLoading ? null : _handleVerify,
        ),
        const SizedBox(height: AppSizes.p16),
        TextButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: Text(
            'Didn’t receive code? Go back',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('success'),
      children: [
        const Icon(LucideIcons.partyPopper, color: AppColors.primary, size: 64),
        const SizedBox(height: AppSizes.p24),
        Text(
          'Account Created!',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Welcome to Vault. Your secure financial future starts now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        const SizedBox(height: AppSizes.p32),
        _buildActionButton(
          text: 'Go to Dashboard',
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              dropdownColor: AppColors.darkBackground,
              icon: Icon(LucideIcons.chevronDown, color: Colors.white.withOpacity(0.4), size: 18),
              style: const TextStyle(color: Colors.white),
              items: _countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedCountry = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secure PIN Setup',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallPinField(
                controller: _pinPart1Controller,
                label: 'PIN',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallPinField(
                controller: _pinPart2Controller,
                label: 'Confirm PIN',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallPinField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, letterSpacing: 8),
        decoration: InputDecoration(
          counterText: '',
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLegalAgreement() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.white.withOpacity(0.4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 16,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.1),
            letterSpacing: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            GestureDetector(
              onTap: () => context.push('/login'),
              child: Text(
                'Sign In',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(LucideIcons.shield, 'Bank-grade'),
            const SizedBox(width: 24),
            _buildBadge(LucideIcons.database, 'Encrypted'),
            const SizedBox(width: 24),
            _buildBadge(LucideIcons.layers, 'Secure'),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
        ),
      ],
    );
  }
}
