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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimaryLight),
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
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildScanQRCard(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildRecipientList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  Widget _buildScanQRCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Instantly pay any Vault user', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.white),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildRecipientList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        List<VaultUser> recipients = [];
        if (state is RecipientsLoaded) {
          recipients = state.searchResults.isNotEmpty ? state.searchResults : state.frequent;
        }

        if (recipients.isEmpty) {
          return const Center(child: Text('No users found', style: TextStyle(color: AppColors.textSecondaryLight)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          itemCount: recipients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = recipients[index];
            return GestureDetector(
              onTap: () => _onRecipientSelected(user),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
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
                          Text(user.kycTag ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondaryLight),
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
