import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Aurora Glows for Dark Mode
          if (isDark) ...[
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
                      AppColors.darkPrimary.withOpacity(0.08),
                      AppColors.darkPrimary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.darkPrimary.withOpacity(0.05),
                      AppColors.darkPrimary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 72), // Space for VaultTopNav (64px + 8px margin)
                  _buildAIInsightWidget(context).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildPortfolioSummaryCard(context).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildCoreAccountCard(context).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildGrowthChart(context).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildQuickSend(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(context).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 120), // Space for bottom dock
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightWidget(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 12),
              Text(
                'AI INSIGHT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You spent 15% less on dining this week compared to last. That’s enough to cover your Netflix subscription!',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(isDark ? 0.7 : 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PORTFOLIO BALANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'KES 428,500.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      '+5.25%',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.chevronRight, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreAccountCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VAULT ACCOUNT',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KES 12,450.00',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(LucideIcons.wallet, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Send'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      theme.colorScheme.onSurface.withOpacity(0.05),
                    ),
                    foregroundColor: WidgetStateProperty.all(theme.textTheme.bodyLarge?.color),
                  ),
                  child: const Text('Deposit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET WORTH GROWTH',
                style: theme.textTheme.labelSmall,
              ),
              const Icon(LucideIcons.lineChart, size: 16),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(2.6, 2),
                      FlSpot(4.9, 5),
                      FlSpot(6.8, 3.1),
                      FlSpot(8, 4),
                      FlSpot(9.5, 3),
                      FlSpot(11, 4),
                    ],
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMinMaxLabel(context, 'Low', 'KES 380,000'),
              _buildMinMaxLabel(context, 'High', 'KES 428,500'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxLabel(BuildContext context, String label, String amount) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: label == 'Low' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
        Text(amount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickSend(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, String>> contacts = [
      {'name': 'Add', 'type': 'action'},
      {'name': 'Nevy', 'initials': 'NV'},
      {'name': 'Sarah', 'initials': 'SR'},
      {'name': 'James', 'initials': 'JM'},
      {'name': 'Elena', 'initials': 'EL'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK SEND',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              if (contact['type'] == 'action') {
                return Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Icon(LucideIcons.plus, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('New', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                );
              }
              return Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      contact['initials']!,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(contact['name']!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final transactions = [
              {
                'title': 'Received from Nevy',
                'time': '2 mins ago',
                'amount': '+ KES 5,000',
                'isPositive': true,
              },
              {
                'title': 'Stripe Subscription',
                'time': '2 hours ago',
                'amount': '- KES 1,500',
                'isPositive': false,
              },
              {
                'title': 'M-Pesa Deposit',
                'time': 'Yesterday',
                'amount': '+ KES 10,000',
                'isPositive': true,
              },
            ];
            final tx = transactions[index];
            final isPositive = tx['isPositive'] as bool;

            return GlassCard(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['title'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(tx['time'] as String, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 0)),
                      ],
                    ),
                  ),
                  Text(
                    tx['amount'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
