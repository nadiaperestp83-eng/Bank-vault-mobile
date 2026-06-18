import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/vault_models.dart';
import 'glass_card.dart';

class AmountEntryDialog extends StatefulWidget {
  final VaultUser recipient;
  final Function(double, String) onConfirm;

  const AmountEntryDialog({
    super.key,
    required this.recipient,
    required this.onConfirm,
  });

  @override
  State<AmountEntryDialog> createState() => _AmountEntryDialogState();
}

class _AmountEntryDialogState extends State<AmountEntryDialog> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'KES';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSizes.p24),
        borderRadius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: widget.recipient.profilePhotoUrl != null
                      ? NetworkImage(widget.recipient.profilePhotoUrl!)
                      : null,
                  child: widget.recipient.profilePhotoUrl == null
                      ? Text(
                          (widget.recipient.firstName?[0] ?? '') + (widget.recipient.lastName?[0] ?? ''),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send to ${widget.recipient.firstName ?? widget.recipient.kycTag}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        widget.recipient.kycTag ?? '',
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedCurrency = _selectedCurrency == 'KES' ? 'USD' : 'KES'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedCurrency, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                          const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount > 0) {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onConfirm(amount, _selectedCurrency);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Confirm Amount', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
