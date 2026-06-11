import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/utils/theme_provider.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vault_os/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:vault_os/src/features/settings/providers.dart';
import 'package:vault_os/src/models/vault_models.dart';
import 'package:vault_os/src/models/receipt_model.dart';
import 'package:vault_os/src/common_widgets/digital_receipt.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/common_widgets/vault_logo.dart';

class VaultTopNav extends ConsumerWidget implements PreferredSizeWidget {
  const VaultTopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : theme.dividerTheme.color?.withValues(alpha: 0.5) ?? theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Left Section: Branding
                _buildLogo(context, authState),
                
                const Spacer(),
                
                // Right Section: Interaction Hub
                _buildInteractionHub(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, VaultAuthState authState) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isLanding = currentPath == '/login' || currentPath == '/signup';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isLanding) {
          context.go('/login');
        } else {
          context.go('/');
        }
      },
      child: const VaultLogo(),
    );
  }

  Widget _buildInteractionHub(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _buildNavButton(
          context: context,
          icon: isDark ? LucideIcons.sun : LucideIcons.moon,
          color: isDark ? Colors.yellow : const Color(0xFF64748B),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark);
          },
          isCircular: true,
          hasGlow: true,
        ),
        const SizedBox(width: 10),
        _buildReceiptButton(context, ref),
        const SizedBox(width: 10),
        _buildNotificationButton(context, ref),
        const SizedBox(width: 10),
        _buildProfileTrigger(context, ref),
      ],
    );
  }

  Widget _buildReceiptButton(BuildContext context, WidgetRef ref) {
    return _buildNavButton(
      context: context,
      icon: LucideIcons.receiptText,
      onTap: () {
        HapticFeedback.lightImpact();
        _showReceiptSheet(context, ref);
      },
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isCircular = false,
    bool hasGlow = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultIconColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isCircular ? 20 : 10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: hasGlow ? [
            BoxShadow(
              color: (color ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Icon(icon, size: 18, color: color ?? defaultIconColor),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (logs) => logs.where((l) => !l.isRead).length,
      orElse: () => 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildNavButton(
          context: context,
          icon: LucideIcons.bell,
          onTap: () {
            HapticFeedback.lightImpact();
            _showNotificationSheet(context, ref);
          },
        ),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms, curve: Curves.easeInOut)
             .then()
             .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1000.ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }

  void _showNotificationSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final notificationsAsync = ref.watch(notificationStreamProvider);
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.p20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => ref.read(dashboardServiceProvider).markAllAsRead(),
                          child: const Text('Mark All as Read'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: notificationsAsync.when(
                      data: (logs) {
                        if (logs.isEmpty) {
                          return const Center(child: Text('No notifications yet'));
                        }
                        
                        // Sort by date descending
                        final sortedLogs = [...logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                          itemCount: sortedLogs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = sortedLogs[index];
                            return _buildNotificationItem(context, ref, log);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, VaultNotification log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestamp = DateFormat('MMM dd').format(log.createdAt);
    
    Color statusColor;
    switch (log.type) {
      case 'success': statusColor = AppColors.success; break;
      case 'warning': statusColor = AppColors.warning; break;
      case 'error': statusColor = AppColors.error; break;
      default: statusColor = AppColors.primary;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () {
        if (!log.isRead) {
          ref.read(dashboardServiceProvider).markAsRead(log.id);
        }
      },
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: log.isRead ? Colors.transparent : statusColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        log.title,
        style: TextStyle(
          fontWeight: log.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timestamp,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      trailing: !log.isRead ? Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
        ),
      ) : null,
    );
  }

  Widget _buildProfileTrigger(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileStreamProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showProfileBottomSheet(context);
      },
      child: profileAsync.when(
        data: (profile) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2),
            image: DecorationImage(
              image: profile?.profilePhotoUrl != null
                  ? NetworkImage(profile!.profilePhotoUrl!)
                  : const NetworkImage('https://i.pravatar.cc/300'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        loading: () => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2),
            color: theme.colorScheme.primary,
          ),
          child: const Icon(LucideIcons.user, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _showReceiptSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSizes.p20),
                child: Row(
                  children: [
                    Text(
                      'Receipt History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final receiptsAsync = ref.watch(receiptsStreamProvider);
                    
                    return receiptsAsync.when(
                      data: (receipts) {
                        if (receipts.isEmpty) {
                          return const Center(child: Text('No receipts found'));
                        }

                        // Sort by date descending
                        final sorted = [...receipts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final receipt = sorted[index];
                            return _buildReceiptItem(context, receipt);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptItem(BuildContext context, VaultReceipt receipt) {
    final theme = Theme.of(context);
    final date = DateFormat('MMM d').format(receipt.createdAt);
    final description = receipt.transactionDetails['description']?.toString() ?? 
                       (receipt.transactionDetails['type']?.toString().toUpperCase() ?? "TRANSACTION");
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.fileText, size: 20, color: AppColors.primary),
      ),
      title: Text(
        description,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        receipt.receiptNumber,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${receipt.currency} ${NumberFormat('#,###.00').format(receipt.amount)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            date,
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
      onTap: () {
        // Show detailed receipt view
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: DigitalReceipt(
              receipt: receipt,
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadReceipt(BuildContext context, VaultReceipt receipt) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading receipt ${receipt.receiptNumber}...')),
    );
    
    // In a real app, this would generate a PDF and save it.
    // For now, we simulate the delay.
    await Future.delayed(const Duration(seconds: 1));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt ${receipt.receiptNumber} saved to downloads.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.user,
                title: 'View Profile',
                onTap: () => Navigator.pop(context),
              ),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              const Divider(indent: 20, endIndent: 20, height: 1),
              _buildBottomSheetItem(
                context: context,
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
