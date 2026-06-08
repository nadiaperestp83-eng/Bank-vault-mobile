import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64), // Space for VaultTopNav
              const Text(
                'Finance Hub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              const SizedBox(height: 8),
              const Text(
                'Grow your wealth and access credit with ease.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 40),
              
              Column(
                children: [
                  _HubCard(
                    title: 'Savings',
                    description: 'Put your money to work.',
                    icon: LucideIcons.piggyBank,
                    color: AppColors.primary,
                    benefits: const [
                      {'icon': LucideIcons.target, 'label': 'Goals'},
                      {'icon': LucideIcons.lock, 'label': 'Locked'},
                      {'icon': LucideIcons.shield, 'label': 'Secure'},
                      {'icon': LucideIcons.trendingUp, 'label': '8% APY'},
                    ],
                    onTap: () => context.push('/finance/savings'),
                  ),
                  const SizedBox(height: 24),
                  _HubCard(
                    title: 'Loans',
                    description: 'Credit when you need it.',
                    icon: LucideIcons.landmark,
                    color: const Color(0xFF334155), // Slate 700
                    benefits: const [
                      {'icon': LucideIcons.zap, 'label': 'Instant'},
                      {'icon': LucideIcons.calendar, 'label': 'Flexible'},
                      {'icon': LucideIcons.percent, 'label': 'Low Int.'},
                      {'icon': LucideIcons.checkCircle, 'label': 'Easy'},
                    ],
                    onTap: () => context.push('/finance/loans'),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> benefits;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.benefits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Image/Icon Area
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 48)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds)
                  .boxShadow(begin: const BoxShadow(blurRadius: 0), end: BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  
                  // Benefit Grid
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: benefits.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Icon(benefits[index]['icon'] as IconData, size: 14, color: color),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                benefits[index]['label'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(LucideIcons.chevronRight, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
