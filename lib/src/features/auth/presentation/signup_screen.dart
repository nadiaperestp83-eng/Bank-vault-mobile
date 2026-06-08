import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
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
    HapticFeedback.mediumImpact();
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
              AppColors.darkBackground.withOpacity(0.95),
              AppColors.primary.withOpacity(0.05),
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
                      borderRadius: 28,
                      padding: const EdgeInsets.all(AppSizes.p24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepper(),
                          const SizedBox(height: AppSizes.p32),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStep(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  _buildFooter().animate().fadeIn(delay: 400.ms),
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
              color: isActive ? AppColors.primary : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4),
              ] : null,
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'Join the elite financial circle today.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
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
        const SizedBox(height: AppSizes.p32),
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
        const Icon(LucideIcons.mailCheck, color: AppColors.primary, size: 52),
        const SizedBox(height: AppSizes.p20),
        Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Text(
          'We\'ve sent a 6-digit code to ${_emailController.text}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.p32),
        _buildOtpInput(),
        const SizedBox(height: AppSizes.p32),
        _buildActionButton(
          text: _isLoading ? 'Verifying...' : 'Verify and continue',
          onPressed: _isLoading ? null : _handleVerify,
        ),
        const SizedBox(height: AppSizes.p16),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _currentStep = 0);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text(
            'Didn’t receive code? Go back',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('success'),
      children: [
        const Icon(LucideIcons.partyPopper, color: AppColors.primary, size: 68),
        const SizedBox(height: AppSizes.p24),
        Text(
          'Account Created!',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Welcome to Vault. Your secure financial future starts now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
        const SizedBox(height: AppSizes.p40),
        _buildActionButton(
          text: 'Go to Dashboard',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('/');
          },
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
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        Text(
          'Country',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              dropdownColor: AppColors.darkBackground,
              icon: Icon(LucideIcons.chevronDown, color: Colors.white.withOpacity(0.3), size: 18),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: _countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  HapticFeedback.selectionClick();
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
        Text(
          'Secure PIN Setup',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallPinField(
                controller: _pinPart1Controller,
                label: '3-digit PIN',
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
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 8),
        decoration: InputDecoration(
          counterText: '',
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _agreeToTerms = value ?? false);
            },
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 18,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.05),
            letterSpacing: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/login');
              },
              child: const Text(
                'Sign In',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(LucideIcons.shield, 'Bank-grade security'),
            const SizedBox(width: 32),
            _buildBadge(LucideIcons.database, 'End-to-end encryption'),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.3), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
