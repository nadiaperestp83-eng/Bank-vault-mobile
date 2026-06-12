import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'scanner_view.dart';
import '../services/kyc_service.dart';

class KycVerificationDialog extends StatelessWidget {
  const KycVerificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shieldCheck, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text('KYC Verification Required', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'To proceed with transactions, please hold your National ID card in the camera frame.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Scaffold(body: ScannerView())),
                    );
                  },
                  icon: const Icon(LucideIcons.camera, size: 18),
                  label: const Text('Start Scan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
