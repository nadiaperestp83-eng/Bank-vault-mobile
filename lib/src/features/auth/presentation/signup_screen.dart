import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

import 'package:vault_os/src/common_widgets/vault_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vault_os/src/services/supabase_service.dart';

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

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
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

    if (_pinPart1Controller.text != _pinPart2Controller.text) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    if (_pinPart1Controller.text.length < 6) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 6 digits')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final pin = _pinPart1Controller.text;
      final hashedPassword = SupabaseService.hashPin(pin);

      await SupabaseService.client.auth.signUp(
        email: _emailController.text,
        password: hashedPassword,
        data: {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'phone': _phoneController.text,
          'full_name': '${_firstNameController.text} ${_lastNameController.text}',
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _handleVerify() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final res = await SupabaseService.client.auth.verifyOTP(
        type: OtpType.signup,
        token: _otpController.text,
        email: _emailController.text,
      );

      if (res.user != null) {
        await SupabaseService.initializeUserDatabase(
          userId: res.user!.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          pin: _pinPart1Controller.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentStep = 2;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
              theme.colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.03),
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
                          _buildStepper(context),
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
                            child: _buildCurrentStep(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  _buildFooter(context).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive ? [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 4),
              ] : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStepOne(context);
      case 1:
        return _buildStepTwo(context);
      case 2:
        return _buildSuccessStep(context);
      default:
        return _buildStepOne(context);
    }
  }

  Widget _buildStepOne(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const VaultLogo(size: 52, borderRadius: 16, fontSize: 28),
        const SizedBox(height: AppSizes.p24),
        Text(
          'Create Your Vault Account',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          'Join the elite financial circle today.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
        ),
        const SizedBox(height: AppSizes.p24),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context: context,
                controller: _firstNameController,
                label: 'First Name',
                hint: 'your name',
                icon: LucideIcons.user,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                context: context,
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'surname',
                icon: LucideIcons.user,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        _buildTextField(
          context: context,
          controller: _emailController,
          label: 'Email Address',
          hint: 'email for verification',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildTextField(
          context: context,
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'for notifications',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildCountrySelector(context),
        const SizedBox(height: AppSizes.p16),
        _buildPinSetup(context),
        const SizedBox(height: AppSizes.p24),
        _buildLegalAgreement(context),
        const SizedBox(height: AppSizes.p32),
        _buildActionButton(
          context: context,
          text: _isLoading ? 'Sending code...' : 'Send code',
          onPressed: _isLoading ? null : _handleSendCode,
        ),
      ],
    );
  }

  Widget _buildStepTwo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const VaultLogo(size: 52, borderRadius: 16, fontSize: 28),
        const SizedBox(height: AppSizes.p20),
        Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Text(
          'We\'ve sent a 6-digit code to ${_emailController.text}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.p32),
        _buildOtpInput(context),
        const SizedBox(height: AppSizes.p32),
        _buildActionButton(
          context: context,
          text: _isLoading ? 'Verifying...' : 'Verify and continue',
          onPressed: _isLoading ? null : _handleVerify,
        ),
        const SizedBox(height: AppSizes.p16),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _currentStep = 0);
          },
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
          child: const Text(
            'Didn’t receive code? Go back',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('success'),
      children: [
        const VaultLogo(size: 68, borderRadius: 20, fontSize: 36),
        const SizedBox(height: AppSizes.p24),
        Text(
          'Account Created!',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Welcome to Vault. Your secure financial future starts now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: AppSizes.p40),
        _buildActionButton(
          context: context,
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
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 14),
              prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              dropdownColor: theme.scaffoldBackgroundColor,
              icon: Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
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

  Widget _buildPinSetup(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Secure PIN Setup',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallPinField(
                context: context,
                controller: _pinPart1Controller,
                label: '6-digit PIN',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallPinField(
                context: context,
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
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, letterSpacing: 8),
        decoration: InputDecoration(
          counterText: '',
          hintText: label,
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 12, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLegalAgreement(BuildContext context) {
    final theme = Theme.of(context);

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
            activeColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 18,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            letterSpacing: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/login');
              },
              child: Text(
                'Sign In',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(context, LucideIcons.shield, 'Bank-grade security'),
            const SizedBox(width: 32),
            _buildBadge(context, LucideIcons.database, 'End-to-end encryption'),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
