import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class BusinessProfileSection extends StatefulWidget {
  const BusinessProfileSection({super.key});

  @override
  State<BusinessProfileSection> createState() => _BusinessProfileSectionState();
}

class _BusinessProfileSectionState extends State<BusinessProfileSection> {
  bool _isMerchantModeEnabled = false;
  String _selectedCategory = 'Retail';
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUSINESS PROFILE',
              style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
            ),
            Switch.adaptive(
              value: _isMerchantModeEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _isMerchantModeEnabled = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        _isMerchantModeEnabled ? _buildActiveForm() : _buildInactiveState(),
      ],
    );
  }

  Widget _buildInactiveState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Column(
        children: [
          Icon(LucideIcons.store, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(height: AppSizes.p16),
          const Text(
            'Enable Merchant Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Accept P2P payments, generate business QRs, and access merchant analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSizes.p24),
          ElevatedButton(
            onPressed: () => setState(() => _isMerchantModeEnabled = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.p12),
              ),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'BUSINESS NAME',
                controller: _businessNameController,
                hint: 'e.g. Acme Corp',
                icon: LucideIcons.building2,
              ),
              const SizedBox(height: AppSizes.p16),
              Text(
                'CATEGORY',
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: AppSizes.p8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: isDark ? AppColors.darkBackground : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  prefixIcon: Icon(LucideIcons.layoutGrid, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                ),
                items: ['Retail', 'Services', 'Food & Drink', 'Tech', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: AppSizes.p16),
              _buildTextField(
                label: 'DESCRIPTION (Max 160 chars)',
                controller: _descriptionController,
                hint: 'Tell customers about your business...',
                icon: LucideIcons.textCursorInput,
                maxLines: 3,
                maxLength: 160,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildQREngine(),
        const SizedBox(height: AppSizes.p16),
        _buildHowItWorks(),
      ],
    );
  }

  Widget _buildQREngine() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        children: [
          const Text(
            'BUSINESS QR ENGINE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: AppSizes.p24),
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.p24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder for QR Code
                const Icon(LucideIcons.qrCode, size: 180, color: AppColors.lightHeading),
                Container(
                  padding: const EdgeInsets.all(AppSizes.p4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.zap, color: AppColors.primary, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: const Text('Download QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.p12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: const Text('Pay Page'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.p12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW IT WORKS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: AppSizes.p16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSizes.p12,
            crossAxisSpacing: AppSizes.p12,
            childAspectRatio: 1.5,
            children: [
              _buildStep(1, 'Setup Profile', LucideIcons.userPlus),
              _buildStep(2, 'Share QR', LucideIcons.share2),
              _buildStep(3, 'Receive Funds', LucideIcons.wallet),
              _buildStep(4, 'Track Growth', LucideIcons.trendingUp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.p12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppSizes.p4),
          Text(
            '$num. $title',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        const SizedBox(height: AppSizes.p8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.p12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.p12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
