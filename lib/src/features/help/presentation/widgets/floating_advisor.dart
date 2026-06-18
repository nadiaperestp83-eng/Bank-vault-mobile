import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/constants/app_colors.dart';

import 'package:vault_os/src/features/transact/presentation/p2p/qr_scanner_screen.dart';
import 'package:vault_os/src/features/transact/presentation/p2p/payment_details_screen.dart';
import 'package:vault_os/src/services/transaction_service.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/services.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';

import 'package:vault_os/src/common_widgets/amount_entry_dialog.dart';
import 'package:vault_os/src/common_widgets/pin_entry_sheet.dart';

import 'package:vault_os/src/common_widgets/kyc_verification_dialog.dart';

class FloatingAdvisor extends StatelessWidget {
  const FloatingAdvisor({super.key});

  void _handleScanResult(BuildContext context, Map<String, String> result) async {
    final txService = context.read<TransactionBloc>().transactionService;
    try {
      // Check KYC status first
      final profile = await txService.getCurrentUserProfile();
      if (profile == null || profile.kycStatus != 'verified') {
        if (context.mounted) {
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

      if (user != null && context.mounted) {
        HapticFeedback.heavyImpact();
        
        // 1. Show Amount Dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AmountEntryDialog(
            recipient: user!,
            onConfirm: (amount, currency) {
              // 2. Show PIN Sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => PinEntrySheet(
                  onConfirm: (pin) {
                    // 3. Dispatch Transfer Event
                    context.read<TransactionBloc>().add(PerformVaultTransfer(
                      recipientTag: user!.kycTag!,
                      amount: amount,
                      currency: currency,
                      pin: pin,
                    ));
                    
                    // Navigate to transaction screen to see progress or just show success
                    // For quick flow, we might stay here or navigate to dashboard
                  },
                ),
              );
            },
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Scan QR Button
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
              if (result != null && result is Map<String, String>) {
                if (context.mounted) {
                  _handleScanResult(context, result);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scanLine, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Scan QR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
           .fadeIn(duration: 400.ms)
           .slideY(begin: 0.2, end: 0)
           .shimmer(delay: 2.seconds, duration: 1.5.seconds),
          
          const SizedBox(height: 12),
          
          // Vault Advisor Button
          GestureDetector(
            onTap: () {
              // Open AI chat page
              context.push('/ai-advisor');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF10B981)], // Premium emerald gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Vault Advisor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3))
           .animate()
           .fadeIn(duration: 500.ms)
           .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
