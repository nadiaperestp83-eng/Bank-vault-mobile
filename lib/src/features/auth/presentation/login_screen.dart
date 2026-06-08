import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isStepTwo = false;
  bool _isLoading = false;
  bool _isPinVisible = false;
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();

  int _resendTimer = 60;
  Timer? _timer;

  void _startTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(SendOtpRequested(_emailController.text));
  }

  void _handleVerify() {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(VerifyOtpRequested(_emailController.text, _otpController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, VaultAuthState>(
      listener: (context, state) {
        if (state is VaultAuthLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is VaultOtpSent) {
          setState(() => _isStepTwo = true);
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully!')),
          );
        }

        if (state is VaultAuthenticated) {
          if (!state.hasProfile) {
            // context.go('/complete-profile');
            context.go('/'); // Defaulting to dashboard for now
          } else if (!state.hasPin) {
            // context.go('/create-pin');
            context.go('/'); // Defaulting to dashboard for now
          } else {
            context.go('/');
          }
        }

        if (state is VaultAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: GlassCard(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(AppSizes.p24),
                        child: AnimatedSwitcher(
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
                          child: _isStepTwo ? _buildStepTwo() : _buildStepOne(),
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
      ),
    );
  }
  Widget _buildStepOne() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildVaultLogo(),
        const SizedBox(height: AppSizes.p20),
        Text(
          'Log In to Your Vault Account',
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
          'Enter your registered email and 6-digit PIN to access your vault.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.p32),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'the account email',
          icon: LucideIcons.mail,
        ),
        const SizedBox(height: AppSizes.p20),
        _buildPinField(),
        const SizedBox(height: AppSizes.p32),
        _buildActionButton(
          text: _isLoading ? 'Sending code...' : 'Send code',
          subtitle: _isLoading ? 'Authenticating...' : null,
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
        _buildVaultLogo(),
        const SizedBox(height: AppSizes.p20),
        Text(
          'Identity Verification',
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
          'We\'ve sent a 6-digit code to your email. Enter it below to continue.',
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
        if (_resendTimer > 0)
          Text(
            'Resend code in ${_resendTimer}s',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          )
        else
          TextButton(
            onPressed: _handleSendCode,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text(
              'Resend Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: AppSizes.p8),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _isStepTwo = false);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.5)),
          child: const Text(
            'Go back',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildVaultLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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

  Widget _buildPinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Secure PIN',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Text(
                'Forgot PIN?',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
            controller: _pinController,
            obscureText: !_isPinVisible,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 6),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 15, letterSpacing: 6),
              prefixIcon: Icon(LucideIcons.lock, color: Colors.white.withOpacity(0.3), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPinVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: Colors.white.withOpacity(0.3),
                  size: 18,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPinVisible = !_isPinVisible);
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
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
    String? subtitle,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
              ),
          ],
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
              'New to Vault? ',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/signup');
              },
              child: const Text(
                'Create Your Account',
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
