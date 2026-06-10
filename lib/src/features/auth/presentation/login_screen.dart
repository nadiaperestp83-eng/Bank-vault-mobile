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
import 'package:vault_os/src/services/biometric_service.dart';
import 'package:vault_os/src/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isStepTwo = false;
  bool _isLoading = false;
  bool _isPinVisible = false;
  bool _isBiometricAvailable = false;
  final _biometricService = BiometricService();
  final _storageService = StorageService();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();

  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final email = await _storageService.getEmail();
    if (email != null && mounted) {
      _emailController.text = email;
    }
  }

  Future<void> _checkBiometrics() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (mounted) {
      setState(() => _isBiometricAvailable = isAvailable);
    }
  }

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

  Future<void> _handleBiometricAuth() async {
    final credentials = await _storageService.getCredentials();
    final savedEmail = credentials['email'];
    final savedPin = credentials['pin'];

    if (savedEmail == null || savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in manually once to enable biometric login')),
      );
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to sign in automatically',
    );

    if (authenticated) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _pinController.text = savedPin;
        });
        _handleSendCode();
      }
    }
  }

  void _handleSendCode() {
    final email = _emailController.text.trim();
    final pin = _pinController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    
    if (pin.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your 6-digit PIN')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(SendOtpRequested(email));
  }

  void _handleVerify() {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(VerifyOtpRequested(email, otp));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          _storageService.saveCredentials(_emailController.text.trim(), _pinController.text.trim());
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
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                theme.colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.03),
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
                          child: _isStepTwo ? _buildStepTwo(context) : _buildStepOne(context),
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
      ),
    );
  }

  Widget _buildStepOne(BuildContext context) {
    final theme = Theme.of(context);
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
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Text(
          'Enter your registered email and 6-digit PIN to access your vault.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.p32),
        _buildTextField(
          context: context,
          controller: _emailController,
          label: 'Email Address',
          hint: 'the account email',
          icon: LucideIcons.mail,
        ),
        const SizedBox(height: AppSizes.p20),
        _buildPinField(context),
        const SizedBox(height: AppSizes.p32),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                text: _isLoading ? 'Sending code...' : 'Send code',
                subtitle: _isLoading ? 'Authenticating...' : null,
                onPressed: _isLoading ? null : _handleSendCode,
              ),
            ),
            if (_isBiometricAvailable) ...[
              const SizedBox(width: AppSizes.p12),
              GestureDetector(
                onTap: _isLoading ? null : _handleBiometricAuth,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    LucideIcons.fingerprint,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ],
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
        _buildVaultLogo(),
        const SizedBox(height: AppSizes.p20),
        Text(
          'Identity Verification',
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
          'We\'ve sent a 6-digit code to your email. Enter it below to continue.',
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
        if (_resendTimer > 0)
          Text(
            'Resend code in ${_resendTimer}s',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
          )
        else
          TextButton(
            onPressed: _handleSendCode,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
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
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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

  Widget _buildPinField(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Secure PIN',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Text(
                'Forgot PIN?',
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
            controller: _pinController,
            obscureText: !_isPinVisible,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, letterSpacing: 6),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 15, letterSpacing: 6),
              prefixIcon: Icon(LucideIcons.lock, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPinVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
    String? subtitle,
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
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
              ),
          ],
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
              'New to Vault? ',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/signup');
              },
              child: Text(
                'Create Your Account',
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
