import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/settings/data/activity_repository.dart';

class ActivityLogDrawer extends ConsumerWidget {
  const ActivityLogDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullLogsAsync = ref.watch(fullLogsProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Row(
                children: [
                  const Icon(LucideIcons.history, color: AppColors.primary),
                  const SizedBox(width: AppSizes.p16),
                  Text(
                    'Full Activity Log',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            Expanded(
              child: fullLogsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('No activity logs found'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final timestamp = DateFormat('MMM dd, yyyy HH:mm').format(log.createdAt);
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          log.actionType, 
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          timestamp, 
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: Icon(
                          LucideIcons.chevronRight, 
                          size: 16,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.p24),
                    child: Text(
                      'Error loading full logs: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
