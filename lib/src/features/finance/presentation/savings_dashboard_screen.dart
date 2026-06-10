import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/finance/presentation/widgets/finance_ledger.dart';
import 'package:vault_os/src/features/finance/presentation/widgets/payment_source_selector.dart';
import 'package:vault_os/src/features/finance/presentation/bloc/savings_bloc.dart';
import 'package:vault_os/src/features/finance/presentation/bloc/savings_event.dart';
import 'package:vault_os/src/features/finance/presentation/bloc/savings_state.dart';
import 'package:vault_os/src/models/vault_models.dart';

class SavingsDashboardScreen extends StatefulWidget {
  const SavingsDashboardScreen({super.key});

  @override
  State<SavingsDashboardScreen> createState() => _SavingsDashboardScreenState();
}

class _SavingsDashboardScreenState extends State<SavingsDashboardScreen> {
  int _activeGoalIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SavingsBloc>().add(FetchGoalsRequested());
  }

  void _onGoalSelected(int index, List<SavingsGoal> goals) {
    setState(() => _activeGoalIndex = index);
    if (index < goals.length) {
      context.read<SavingsBloc>().add(FetchLedgerRequested(goals[index].id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavingsBloc, SavingsState>(
      listener: (context, state) {
        if (state is SavingsLoaded && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is SavingsInitial || state is SavingsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is SavingsError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }

        if (state is SavingsLoaded) {
          final goals = state.goals;
          
          // If goals list was empty but now has items, trigger ledger fetch for the first goal
          if (goals.isNotEmpty && state.selectedGoalLedger.isEmpty && _activeGoalIndex == 0) {
            context.read<SavingsBloc>().add(FetchLedgerRequested(goals[0].id));
          }

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
                  _buildGoalSwitcher(goals),
                  const SizedBox(height: 24),
                  if (goals.isNotEmpty) ...[
                    _buildProgressCard(goals[_activeGoalIndex], state.selectedGoalLedger),
                    const SizedBox(height: 24),
                    _buildAITipWidget(),
                    const SizedBox(height: 32),
                    FinanceLedger(
                      transactions: state.selectedGoalLedger.map((e) => {
                        'date': DateFormat('MMM d').format(e.createdAt),
                        'source': e.source,
                        'type': e.type[0].toUpperCase() + e.type.substring(1),
                        'amount': '+ KES ${NumberFormat('#,###').format(e.amount)}',
                      }).toList(),
                    ),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(LucideIcons.piggyBank, size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          const Text('No Savings Goals Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Start your journey by creating a goal.\nYou can have up to 2 active goals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateGoalDialog(),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Create First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSwitcher(List<SavingsGoal> goals) {
    final displayGoals = goals.map((e) => e.title).toList();
    if (goals.length < 2) displayGoals.add('Add New');

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayGoals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          bool isActive = _activeGoalIndex == index;
          bool isAdd = index == displayGoals.length - 1 && goals.length < 2 && goals.length != displayGoals.length;
          // Correction for "Add New" detection
          if (index == goals.length && goals.length < 2) isAdd = true;
          
          return GestureDetector(
            onTap: () {
              if (isAdd) {
                _showCreateGoalDialog();
              } else {
                _onGoalSelected(index, goals);
              }
            },
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
                    displayGoals[index],
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

  Widget _buildProgressCard(SavingsGoal goal, List<SavingsLedgerEntry> ledger) {
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
                  Text(
                    'KES ${NumberFormat('#,###').format(goal.currentAmount)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of KES ${NumberFormat('#,###').format(goal.targetAmount)} target',
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
                      value: goal.progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${goal.daysRemaining > 0 ? goal.daysRemaining : 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Text('days', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${(goal.progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
                    spots: _getSpotsFromLedger(ledger),
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
            onPressed: () => _showContributionDialog(goal),
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

  List<FlSpot> _getSpotsFromLedger(List<SavingsLedgerEntry> ledger) {
    if (ledger.isEmpty) return [const FlSpot(0, 0)];
    
    // Sort by date ascending
    final sorted = ledger.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Take last 7 entries or group by day
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].runningTotal));
    }
    
    if (spots.length == 1) return [const FlSpot(0, 0), spots[0]];
    return spots;
  }

  void _showCreateGoalDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title (e.g. Dream Car)')),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Target Amount (KES)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final title = titleController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              if (title.isNotEmpty && amount > 0) {
                this.context.read<SavingsBloc>().add(CreateGoalRequested(
                  title: title,
                  targetAmount: amount,
                  deadline: DateTime.now().add(const Duration(days: 30)),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showContributionDialog(SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribute to ${goal.title}'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                PaymentSourceSelector.show(this.context, 'Contribute to Savings', (source) {
                  this.context.read<SavingsBloc>().add(AddContributionRequested(
                    goal: goal,
                    amount: amount,
                    source: source,
                  ));
                });
              }
            },
            child: const Text('Next'),
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
