import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_bloc.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_event.dart';
import 'package:vault_os/src/features/transact/bloc/transaction_state.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:flutter/services.dart';
import 'payment_details_screen.dart';

class RecipientDiscoveryScreen extends StatefulWidget {
  const RecipientDiscoveryScreen({super.key});

  @override
  State<RecipientDiscoveryScreen> createState() => _RecipientDiscoveryScreenState();
}

class _RecipientDiscoveryScreenState extends State<RecipientDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadFrequentRecipients());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onRecipientSelected(VaultUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(recipient: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(
              children: [
                _buildSearchBar(isDark),
                const SizedBox(height: 24),
                _buildScanQRCard(isDark),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildRecipientList(isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
    return TextField(
      controller: _searchController,
      onChanged: (v) => context.read<TransactionBloc>().add(SearchRecipients(v)),
      decoration: InputDecoration(
        hintText: 'Search by @username or name',
        prefixIcon: const Icon(LucideIcons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () {
                _searchController.clear();
                context.read<TransactionBloc>().add(LoadFrequentRecipients());
              })
            : null,
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildScanQRCard(bool isDark) {
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Scanner...')));
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.qrCode, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Instantly pay any Vault user', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: secondaryTextColor),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildRecipientList(bool isDark) {
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        List<VaultUser> recipients = [];
        if (state is RecipientsLoaded) {
          recipients = state.searchResults.isNotEmpty ? state.searchResults : state.frequent;
        }

        if (recipients.isEmpty) {
          return Center(child: Text('No users found', style: TextStyle(color: secondaryTextColor)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          itemCount: recipients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = recipients[index];
            return GestureDetector(
              onTap: () => _onRecipientSelected(user),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (user.firstName?[0] ?? '') + (user.lastName?[0] ?? ''),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(user.kycTag ?? '', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: secondaryTextColor),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
