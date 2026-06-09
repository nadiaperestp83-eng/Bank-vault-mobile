import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/finance/presentation/widgets/finance_ledger.dart';

import 'package:vault_os/src/features/finance/presentation/widgets/payment_source_selector.dart';

class SavingsDashboardScreen extends StatefulWidget {
  const SavingsDashboardScreen({super.key});

  @override
  State<SavingsDashboardScreen> createState() => _SavingsDashboardScreenState();
}

class _SavingsDashboardScreenState extends State<SavingsDashboardScreen> {
  int _activeGoalIndex = 0;
  final List<String> _goals = ['Goal 1', 'Goal 2', 'Goal 3', 'Add New'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('The Vault', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalSwitcher(),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildAITipWidget(),
            const SizedBox(height: 32),
            const FinanceLedger(
              transactions: [
                {'date': 'Jun 8', 'source': 'M-Pesa', 'type': 'Automated', 'amount': '+ KES 500'},
                {'date': 'Jun 7', 'source': 'Vault Bal', 'type': 'Manual', 'amount': '+ KES 1,200'},
                {'date': 'Jun 5', 'source': 'Stripe', 'type': 'Automated', 'amount': '+ KES 3,000'},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSwitcher() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _goals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          bool isActive = _activeGoalIndex == index;
          bool isAdd = index == _goals.length - 1;
          
          return GestureDetector(
            onTap: () => setState(() => _activeGoalIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (isAdd) const Icon(LucideIcons.plus, size: 16, color: AppColors.textSecondaryLight),
                  if (isAdd) const SizedBox(width: 4),
                  Text(
                    _goals[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Amount', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text(
                    'KES 45,200',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of KES 100,000 target',
                    style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 0.45,
                      strokeWidth: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const Column(
                    children: [
                      Text('12', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('days', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Visual Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('45%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.45,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Growth Chart
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Savings Growth (7d)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 1.2),
                      FlSpot(3, 2.5),
                      FlSpot(4, 2),
                      FlSpot(5, 3.5),
                      FlSpot(6, 4.5),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => PaymentSourceSelector.show(context, 'Contribute to Savings'),
            icon: const Icon(LucideIcons.piggyBank, size: 20),
            label: const Text('Add Savings', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Savings Tip',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Next Tip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Why did the piggy bank go to the doctor? It had a case of "thin-wallet-itis"! Tip: Automate your savings to avoid the symptoms.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimaryLight),
          ),
        ],
      ).animate().shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2)),
    );
  }
}
