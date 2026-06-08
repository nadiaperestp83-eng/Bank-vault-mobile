import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.p16),
              _buildTopNav(),
              const SizedBox(height: 24),
              _buildAIInsightWidget().animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildPortfolioSummaryCard().animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildCoreAccountCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildGrowthChart().animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildQuickSend().animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildRecentTransactions().animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 100), // Space for bottom dock
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Row(
      children: [
        // Left: Minimalist logo
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.vault, color: AppColors.primary, size: 24),
        ),
        const Spacer(),
        // Right Actions
        Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(LucideIcons.sun, size: 20)),
            IconButton(onPressed: () {}, icon: const Icon(LucideIcons.receiptText, size: 20)),
            Stack(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell, size: 20)),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Icon(LucideIcons.user, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIInsightWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Spending Tip',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You spent 15% less on dining this week compared to last. That’s enough to cover your Netflix subscription!',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark.withOpacity(0.9),
          ],
          center: Alignment.topLeft,
          radius: 1.5,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+5.25%',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'KES 428,500.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Detailed Report', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreAccountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vault Account',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'KES 12,450.00',
            style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryLight,
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Worth Growth',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ['TX', 'DAY', 'WK', 'MO'].map((label) {
                    bool isSelected = label == 'MO';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
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
              _buildMinMaxLabel('Low', 'KES 380,000'),
              _buildMinMaxLabel('High', 'KES 428,500'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxLabel(String label, String amount) {
    return Column(
      crossAxisAlignment: label == 'Low' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickSend() {
    final List<Map<String, String>> contacts = [
      {'name': 'Add', 'type': 'action'},
      {'name': 'Nevy', 'initials': 'NV'},
      {'name': 'Sarah', 'initials': 'SR'},
      {'name': 'James', 'initials': 'JM'},
      {'name': 'Elena', 'initials': 'EL'},
      {'name': 'Mike', 'initials': 'MK'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Send',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.plus, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    const Text('New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                );
              }
              return Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: Text(
                      contact['initials']!,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(contact['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Send', 'Received', 'Deposit', 'Withdraw'].map((filter) {
              bool isSelected = filter == 'All';
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) {},
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.05)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const Divider(height: 32, thickness: 0.5),
          itemBuilder: (context, index) {
            final transactions = [
              {
                'title': 'Received from Nevy',
                'time': '2 mins ago',
                'amount': '+ KES 5,000',
                'balance': 'KES 12,450',
                'isPositive': true,
                'initials': 'NV'
              },
              {
                'title': 'Stripe Subscription',
                'time': '2 hours ago',
                'amount': '- KES 1,500',
                'balance': 'KES 7,450',
                'isPositive': false,
                'initials': 'ST'
              },
              {
                'title': 'M-Pesa Deposit',
                'time': 'Yesterday',
                'amount': '+ KES 10,000',
                'balance': 'KES 8,950',
                'isPositive': true,
                'initials': 'MP'
              },
            ];
            final tx = transactions[index];
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (tx['isPositive'] as bool ? Colors.green : Colors.red).withOpacity(0.1),
                  child: Text(
                    tx['initials'] as String,
                    style: TextStyle(
                      color: tx['isPositive'] as bool ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(tx['time'] as String, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tx['amount'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx['isPositive'] as bool ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      tx['balance'] as String,
                      style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
