import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/services/auth_service.dart';
import 'package:vault_os/src/utils/security_utils.dart';
import 'package:go_router/go_router.dart';

enum ChangePinStep { currentPin, otp, newPin, confirmPin, success }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  ChangePinStep _currentStep = ChangePinStep.currentPin;
  String _currentPin = '';
  String _otp = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  void _onKeyTap(String key) {
    setState(() => _errorMessage = null);
    
    switch (_currentStep) {
      case ChangePinStep.currentPin:
        if (_currentPin.length < 6) {
          setState(() => _currentPin += key);
          if (_currentPin.length == 6) _verifyCurrentPin();
        }
        break;
      case ChangePinStep.otp:
        if (_otp.length < 6) {
          setState(() => _otp += key);
          if (_otp.length == 6) _verifyOtp();
        }
        break;
      case ChangePinStep.newPin:
        if (_newPin.length < 6) {
          setState(() => _newPin += key);
          if (_newPin.length == 6) setState(() => _currentStep = ChangePinStep.confirmPin);
        }
        break;
      case ChangePinStep.confirmPin:
        if (_confirmPin.length < 6) {
          setState(() => _confirmPin += key);
          if (_confirmPin.length == 6) _finalizePinChange();
        }
        break;
      case ChangePinStep.success:
        break;
    }
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      switch (_currentStep) {
        case ChangePinStep.currentPin:
          if (_currentPin.isNotEmpty) _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          break;
        case ChangePinStep.otp:
          if (_otp.isNotEmpty) _otp = _otp.substring(0, _otp.length - 1);
          break;
        case ChangePinStep.newPin:
          if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
          break;
        case ChangePinStep.confirmPin:
          if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          break;
        case ChangePinStep.success:
          break;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _verifyCurrentPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hashedPin = SecurityUtils.hashPin(_currentPin);
      final isValid = await _authService.verifyCurrentPin(hashedPin);

      if (isValid) {
        final email = _authService.currentUser?.email;
        if (email != null) {
          await _authService.triggerPinResetOtp(email);
          setState(() => _currentStep = ChangePinStep.otp);
        } else {
          setState(() => _errorMessage = 'User email not found.');
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect current PIN.';
          _currentPin = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _currentPin = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _authService.currentUser?.email;
      if (email != null) {
        await _authService.verifyPinResetOtp(email, _otp);
        setState(() => _currentStep = ChangePinStep.newPin);
      } else {
        setState(() => _errorMessage = 'User email not found.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid or expired OTP.';
        _otp = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizePinChange() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match.';
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final hashedPin = SecurityUtils.hashPin(_newPin);
        await _authService.updatePin(userId, hashedPin);
        setState(() => _currentStep = ChangePinStep.success);
      } else {
        setState(() => _errorMessage = 'User session not found.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update PIN. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                child: Column(
                  children: [
                    _buildHeader(secondaryTextColor),
                    const SizedBox(height: 40),
                    _buildPinDisplay(isDark),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_isLoading) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ],
                ),
              ),
            ),
            _buildKeypad(primaryTextColor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color secondaryTextColor) {
    String title = '';
    String subtitle = '';
    IconData icon = LucideIcons.lock;

    switch (_currentStep) {
      case ChangePinStep.currentPin:
        title = 'Verify Current PIN';
        subtitle = 'Enter your current 6-digit transaction PIN';
        break;
      case ChangePinStep.otp:
        title = 'Verify Identity';
        subtitle = 'We\'ve sent a 6-digit code to your email';
        icon = LucideIcons.mail;
        break;
      case ChangePinStep.newPin:
        title = 'Create New PIN';
        subtitle = 'Enter a new 6-digit transaction PIN';
        icon = LucideIcons.shieldCheck;
        break;
      case ChangePinStep.confirmPin:
        title = 'Confirm New PIN';
        subtitle = 'Please re-enter your new PIN to confirm';
        icon = LucideIcons.shieldCheck;
        break;
      case ChangePinStep.success:
        title = 'PIN Changed!';
        subtitle = 'Your transaction PIN has been updated successfully';
        icon = LucideIcons.checkCircle;
        break;
    }

    if (_currentStep == ChangePinStep.success) {
      return Column(
        children: [
          Icon(icon, size: 64, color: AppColors.success),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor, fontSize: 16)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildPinDisplay(bool isDark) {
    int length = 0;
    switch (_currentStep) {
      case ChangePinStep.currentPin: length = _currentPin.length; break;
      case ChangePinStep.otp: length = _otp.length; break;
      case ChangePinStep.newPin: length = _newPin.length; break;
      case ChangePinStep.confirmPin: length = _confirmPin.length; break;
      case ChangePinStep.success: return const SizedBox();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(Color primaryTextColor) {
    if (_currentStep == ChangePinStep.success) return const SizedBox();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((key) => _buildKey(key, primaryTextColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((key) => _buildKey(key, primaryTextColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((key) => _buildKey(key, primaryTextColor)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _buildKey('0', primaryTextColor),
            _buildBackspaceKey(primaryTextColor),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String label, Color primaryTextColor) {
    return InkWell(
      onTap: () => _onKeyTap(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(Color primaryTextColor) {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Icon(LucideIcons.delete, color: primaryTextColor),
      ),
    );
  }
}
