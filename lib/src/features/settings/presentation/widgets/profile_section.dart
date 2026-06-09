import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/profile_model.dart';

class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({super.key});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      final settingsService = ref.read(settingsServiceProvider);
      final profile = ref.read(profileStreamProvider).value;
      if (profile != null) {
        await settingsService.uploadAvatar(profile.id, File(pickedFile.path));
      }
    }
  }

  Future<void> _saveProfile() async {
    final profile = ref.read(profileStreamProvider).value;
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      await ref.read(settingsServiceProvider).updateProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        if (!_isInitialized) {
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
          _isInitialized = true;
        }

        final isVerified = profile.kycStatus == 'verified';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFILE & IDENTITY',
              style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: AppSizes.p16),
            GlassCard(
              child: Column(
                children: [
                  // Avatar Management
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullImage(context, profile.profilePhotoUrl),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                              image: DecorationImage(
                                image: profile.profilePhotoUrl != null
                                    ? NetworkImage(profile.profilePhotoUrl!)
                                    : const NetworkImage('https://i.pravatar.cc/300'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showImagePickerSourceDialog(),
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.p4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),

                  // Verification Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                      vertical: AppSizes.p4,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isVerified ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                          size: 14,
                          color: isVerified ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: AppSizes.p4),
                        Text(
                          isVerified ? 'Verified' : 'Unverified',
                          style: TextStyle(
                            color: isVerified ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Identity Tags (Non-editable)
                  _buildReadOnlyField(
                    context: context,
                    label: 'KYC TAG',
                    value: profile.kycTag,
                    icon: LucideIcons.atSign,
                    isMonospace: true,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Edit Fields
                  _buildEditField(
                    label: 'FIRST NAME',
                    controller: _firstNameController,
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  _buildEditField(
                    label: 'LAST NAME',
                    controller: _lastNameController,
                    icon: LucideIcons.user,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.p12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
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
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter $label',
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.p12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
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
        Container(
          padding: const EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppSizes.p12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(width: AppSizes.p12),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontFamily: isMonospace ? 'monospace' : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.lock, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ],
          ),
        ),
      ],
    );
  }

  void _showImagePickerSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Hero(
          tag: 'avatar',
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.p20),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
