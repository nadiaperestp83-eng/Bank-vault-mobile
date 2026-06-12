import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) _buildAuroraGlows(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64), // Space for VaultTopNav
                  
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  _buildQuickStats(context),
                  const SizedBox(height: 40),
                  
                  Text(
                    'FINANCIAL PRODUCTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),

                  _buildFinanceProductCard(
                    context: context,
                    title: 'The Vault',
                    subtitle: 'High-Yield Savings',
                    description: 'Set goals, automate contributions, and earn up to 8% APY on your idle capital.',
                    icon: LucideIcons.piggyBank,
                    gradient: const [AppColors.primary, Color(0xFF10B981)],
                    onTap: () => context.push('/finance/savings'),
                    delay: 300.ms,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFinanceProductCard(
                    context: context,
                    title: 'Credit Line',
                    subtitle: 'Instant Liquidity',
                    description: 'Access low-interest loans backed by your assets with flexible repayment terms.',
                    icon: LucideIcons.landmark,
                    gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    onTap: () => context.push('/finance/loans'),
                    delay: 450.ms,
                  ),
                  
                  const SizedBox(height: 120), // Padding for bottom nav + FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finance Hub',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        Text(
          'Architect your wealth with precision tools.',
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context, 
            'Active Goals', 
            '2', 
            LucideIcons.target,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            context, 
            'Credit Score', 
            '742', 
            LucideIcons.shieldCheck,
            const Color(0xFF6366F1),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, 
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceProductCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                ),
              ),
              
              // Decorative Gradient Corner
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gradient[0].withValues(alpha: 0.15),
                        gradient[0].withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        Icon(
                          LucideIcons.arrowUpRight, 
                          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        color: gradient[0],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildAuroraGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.darkPrimary.withValues(alpha: 0.08),
                  AppColors.darkPrimary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                  const Color(0xFF6366F1).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
