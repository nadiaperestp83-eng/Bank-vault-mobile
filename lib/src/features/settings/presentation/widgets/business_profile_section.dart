import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_share_plus/social_share_plus.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/merchant_model.dart';
import 'package:vault_os/src/models/profile_model.dart';

class BusinessProfileSection extends ConsumerStatefulWidget {
  const BusinessProfileSection({super.key});

  @override
  ConsumerState<BusinessProfileSection> createState() => _BusinessProfileSectionState();
}

class _BusinessProfileSectionState extends ConsumerState<BusinessProfileSection> {
  final GlobalKey _qrKey = GlobalKey();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  String _selectedCategory = 'Retail';

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _toggleMerchantMode(bool enabled, String userId) async {
    if (enabled) {
      await ref.read(settingsServiceProvider).activateMerchantMode(
        userId,
        _businessNameController.text.isEmpty ? 'My Business' : _businessNameController.text,
        _selectedCategory,
      );
    }
  }

  Future<void> _shareQR() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/business_qr.png').create();
      await imagePath.writeAsBytes(pngBytes);

      await SocialSharePlus.shareToSocialMedia('My Business QR Code', path: imagePath.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing QR: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final merchantsAsync = ref.watch(merchantsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return merchantsAsync.when(
          data: (merchants) {
            final activeMerchant = merchants.isEmpty ? null : merchants.firstWhere((m) => m.isActive, orElse: () => merchants.first);
            final isMerchantModeEnabled = activeMerchant?.isActive ?? false;

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
                      value: isMerchantModeEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (value) => _toggleMerchantMode(value, profile.id),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),
                isMerchantModeEnabled 
                  ? _buildActiveForm(profile, activeMerchant) 
                  : _buildInactiveState(profile.id),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildInactiveState(String userId) {
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
            onPressed: () => _toggleMerchantMode(true, userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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

  Widget _buildActiveForm(Profile profile, Merchant? merchant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (merchant != null && _businessNameController.text.isEmpty) {
      _businessNameController.text = merchant.businessName;
      _selectedCategory = merchant.businessType;
    }

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
                value: ['Retail', 'Services', 'Food & Drink', 'Tech', 'Other'].contains(_selectedCategory) 
                    ? _selectedCategory 
                    : 'Retail',
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
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                ),
                items: ['Retail', 'Services', 'Food & Drink', 'Tech', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        _buildQREngine(profile),
        const SizedBox(height: AppSizes.p16),
        _buildHowItWorks(),
      ],
    );
  }

  Widget _buildQREngine(Profile profile) {
    final String baseUrl = 'https://vault.os';
    final String payUrl = '$baseUrl/pay/${profile.kycTag.replaceAll('@', '')}';

    return GlassCard(
      child: Column(
        children: [
          const Text(
            'BUSINESS QR ENGINE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: AppSizes.p24),
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.p24),
              ),
              child: QrImageView(
                data: payUrl,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareQR,
                  icon: const Icon(LucideIcons.share2, size: 18),
                  label: const Text('Share QR'),
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
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
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
