import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          
          if (goals.isNotEmpty && state.selectedGoalLedger.isEmpty && _activeGoalIndex == 0) {
            context.read<SavingsBloc>().add(FetchLedgerRequested(goals[0].id));
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'The Vault', 
                style: TextStyle(
                  color: theme.colorScheme.onSurface, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: Stack(
              children: [
                if (isDark) _buildAuroraGlows(),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 110),
                      
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      
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
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Savings Management',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),
        Text(
          'Track your progress and grow your capital.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildAuroraGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
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
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.piggyBank, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text('No Active Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Your wealth starts with a plan.\nCreate your first savings goal now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateGoalDialog(),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Start Saving', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildGoalSwitcher(List<SavingsGoal> goals) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayGoals = goals.map((e) => e.title).toList();
    if (goals.length < 2) displayGoals.add('Add New');

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayGoals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          bool isActive = _activeGoalIndex == index;
          bool isAdd = index == goals.length && goals.length < 2;
          
          return GestureDetector(
            onTap: () {
              if (isAdd) {
                _showCreateGoalDialog();
              } else {
                _onGoalSelected(index, goals);
              }
            },
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (isAdd) Icon(LucideIcons.plus, size: 14, color: isDark ? Colors.white70 : Colors.black45),
                  if (isAdd) const SizedBox(width: 6),
                  Text(
                    displayGoals[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                  Text('ACCUMULATED', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(
                    'KES ${NumberFormat('#,###').format(goal.currentAmount)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: KES ${NumberFormat('#,###').format(goal.targetAmount)}',
                    style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              _buildProgressCircle(goal),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                  Text('${(goal.progress * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('GROWTH TRAJECTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
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
                    isStrokeCapRound: true,
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
          ElevatedButton(
            onPressed: () => _showContributionDialog(goal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plusCircle, size: 20),
                SizedBox(width: 10),
                Text('Add Contribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(SavingsGoal goal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: CircularProgressIndicator(
            value: goal.progress,
            strokeWidth: 9,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          children: [
            Text(
              '${goal.daysRemaining > 0 ? goal.daysRemaining : 0}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Text('DAYS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  List<FlSpot> _getSpotsFromLedger(List<SavingsLedgerEntry> ledger) {
    if (ledger.isEmpty) return [const FlSpot(0, 0)];
    final sorted = ledger.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Savings Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController, 
              decoration: InputDecoration(
                labelText: 'Title', 
                hintText: 'e.g. Dream Car',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController, 
              decoration: InputDecoration(
                labelText: 'Target Amount (KES)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add to ${goal.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Amount (KES)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                PaymentSourceSelector.show(this.context, 'Select Funding Source', (source) {
                  this.context.read<SavingsBloc>().add(AddContributionRequested(
                    goal: goal,
                    amount: amount,
                    source: source,
                  ));
                });
              }
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
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
                'STRATEGIC TIP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accent, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Users who set automated contributions are 3x more likely to hit their goals on time. Consider enabling weekly recurring deposits.',
            style: TextStyle(
              fontSize: 14, 
              height: 1.5, 
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ).animate().shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2)),
    );
  }
}
