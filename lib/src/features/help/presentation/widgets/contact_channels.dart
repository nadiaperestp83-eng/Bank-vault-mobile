import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContactChannels extends StatefulWidget {
  const ContactChannels({super.key});

  @override
  State<ContactChannels> createState() => _ContactChannelsState();
}

class _ContactChannelsState extends State<ContactChannels> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildContactCard(
          index: 0,
          icon: LucideIcons.phone,
          title: 'Direct Call',
          subtitle: 'Talk to an agent now',
          status: 'ALWAYS ONLINE',
          onTap: () {
            setState(() => _selectedIndex = 0);
            _showCallbackDialog(context);
          },
        ),
        const SizedBox(height: AppSizes.p16),
        _buildContactCard(
          index: 1,
          icon: LucideIcons.mail,
          title: 'Official Email',
          subtitle: 'support@vaultos.com',
          status: '24H RESPONSE',
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppSizes.p20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : (isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSizes.p20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ).then().scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(0.8, 0.8),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCallbackDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Callback',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(AppSizes.p32),
            padding: const EdgeInsets.all(AppSizes.p24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.phoneIncoming, size: 48, color: colorScheme.primary),
                  const SizedBox(height: AppSizes.p16),
                  Text(
                    'Callback Request',
                    style: TextStyle(
                      color: theme.textTheme.headlineSmall?.color,
                      fontSize: 22, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Text(
                    'Would you like to call us directly or schedule a return call?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: AppSizes.p24),
                  TextField(
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Your Phone Number',
                      hintStyle: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Call Now', style: TextStyle(color: colorScheme.primary)),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Schedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}
