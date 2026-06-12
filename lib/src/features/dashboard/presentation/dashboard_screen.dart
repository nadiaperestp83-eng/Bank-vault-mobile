import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:vault_os/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:vault_os/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';
import 'package:vault_os/src/common_widgets/digital_receipt.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/vault_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listenWhen: (previous, current) {
          if (previous is DashboardLoaded && current is DashboardLoaded) {
            return current.receipts.length > previous.receipts.length;
          }
          return false;
        },
        listener: (context, state) {
          if (state is DashboardLoaded) {
            if (!state.user.hasPin) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please set up your Transaction PIN to continue.')),
              );
            }

            if (state.receipts.isNotEmpty) {
              final latestReceipt = state.receipts.first;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('New Receipt Available: ${latestReceipt.receiptNumber} for ${latestReceipt.currency} ${latestReceipt.amount}'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: DigitalReceipt(receipt: latestReceipt),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            return Stack(
              children: [
                if (isDark) _buildAuroraGlows(),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 72),
                        
                        _buildGreeting(context, state.user),
                        const SizedBox(height: 24),

                        _buildAIInsightWidget(context, state.latestInsight)
                            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),

                        _buildPortfolioSummaryCard(context, state)
                            .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),

                        ...state.notifications
                            .where((n) => n.type == 'warning')
                            .map((n) => _buildWarningBanner(context, n)),
                        
                        const SizedBox(height: 24),
                        
                        _buildCoreAccountCard(context, state.wallet, state.user.primaryCurrency)
                            .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        _buildGrowthChart(context, state.growthData)
                            .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        _buildQuickSend(context, state.frequentContacts, state.suggestedUsers)
                            .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),
                        
                        _buildRecentTransactions(context, state.transactions)
                            .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
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
    );
  }

  Widget _buildWarningBanner(BuildContext context, VaultNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.message,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightWidget(BuildContext context, String? insight) {
    return _AIInsightCard(initialInsight: insight);
  }

  Widget _buildPortfolioSummaryCard(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryBalance = CurrencyFormatter.format(state.wallet.balance, state.wallet.currency);
    final secondaryCurrency = state.wallet.currency == 'USD' ? 'KES' : 'USD';
    final rate = state.currencyRates[secondaryCurrency] ?? 130.0;
    final secondaryBalance = CurrencyFormatter.format(
      CurrencyFormatter.convert(state.wallet.balance, state.wallet.currency, secondaryCurrency, rate: rate),
      secondaryCurrency,
    );

    final growth = (state.growthData['growth'] as num?)?.toDouble() ?? 0.0;
    final trend = (state.growthData['trend'] as String?) ?? 'neutral';

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
          Text(
            primaryBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            '≈ $secondaryBalance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
                child: Row(
                  children: [
                    Icon(
                      trend == 'positive' ? LucideIcons.trendingUp : (trend == 'negative' ? LucideIcons.trendingDown : LucideIcons.minus),
                      color: Colors.white, 
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${growth.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildCoreAccountCard(BuildContext context, Wallet wallet, String primaryCurrency) {
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
                CurrencyFormatter.format(wallet.balance, wallet.currency),
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
                  onPressed: () => context.go('/transact'),
                  child: const Text('Send'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/transact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
                    foregroundColor: theme.textTheme.bodyLarge?.color,
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

  Widget _buildGrowthChart(BuildContext context, Map<String, dynamic> growthData) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final List<double> history = List<double>.from(growthData['history'] ?? []);

    if (history.isEmpty) return const SizedBox.shrink();

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

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
                    spots: spots,
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
        ],
      ),
    );
  }

  Widget _buildQuickSend(BuildContext context, List<VaultUser> frequent, List<VaultUser> suggested) {
    final theme = Theme.of(context);
    
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddAction(context),
              const SizedBox(width: 20),
              ...frequent.map((user) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _buildContactAvatar(context, user, isFrequent: true),
              )),
              ...suggested.map((user) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _buildContactAvatar(context, user),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAction(BuildContext context) {
    final theme = Theme.of(context);
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

  Widget _buildContactAvatar(BuildContext context, VaultUser user, {bool isFrequent = false}) {
    final theme = Theme.of(context);
    final initials = ((user.firstName?.isNotEmpty ?? false) ? user.firstName![0] : '') + 
                     ((user.lastName?.isNotEmpty ?? false) ? user.lastName![0] : '');
    
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: isFrequent ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
          child: user.profilePhotoUrl == null ? Text(
            initials,
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ) : null,
        ),
        const SizedBox(height: 8),
        Text(user.firstName ?? 'User', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List<VaultTransaction> transactions) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          const GlassCard(child: Center(child: Text('No recent transactions.')))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isPositive = tx.type == 'deposit' || (tx.type == 'transfer' && tx.receiverId == Supabase.instance.client.auth.currentUser?.id);
              
              return GlassCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Row(
                  children: [
                    _buildTransactionIcon(context, tx, isPositive),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getTransactionTitle(tx), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_formatTimestamp(tx.createdAt), style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 0)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : '-'} ${CurrencyFormatter.format(tx.amount, tx.currency)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.success : AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                        if (tx.recordedBalance != null)
                          Text(
                            'Bal: ${CurrencyFormatter.format(tx.recordedBalance!, tx.currency)}',
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTransactionIcon(BuildContext context, VaultTransaction tx, bool isPositive) {
    IconData icon;
    Color color;
    String? logoPath;
    String? profilePhotoUrl;
    String? initials;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isTransfer = tx.type == 'transfer';

    if (isTransfer) {
      final otherProfile = tx.senderId == currentUserId ? tx.receiverProfile : tx.senderProfile;
      if (otherProfile != null) {
        profilePhotoUrl = otherProfile.profilePhotoUrl;
        initials = ((otherProfile.firstName?.isNotEmpty ?? false) ? otherProfile.firstName![0] : '') + 
                   ((otherProfile.lastName?.isNotEmpty ?? false) ? otherProfile.lastName![0] : '');
      }
    }

    final method = tx.method?.toLowerCase() ?? '';
    final description = tx.description?.toLowerCase() ?? '';

    // Map method/description to logo assets
    if (method.contains('mpesa') || description.contains('mpesa')) {
      logoPath = 'assets/logos/mpesa.svg';
    } else if (method.contains('kcb') || description.contains('kcb')) {
      logoPath = 'assets/logos/kcb.svg';
    } else if (method.contains('absa') || description.contains('absa')) {
      logoPath = 'assets/logos/absa.svg';
    } else if (method.contains('equity') || description.contains('equity')) {
      logoPath = 'assets/logos/equity.svg';
    } else if (method.contains('co-op') || method.contains('coop') || description.contains('coop')) {
      logoPath = 'assets/logos/coop.svg';
    } else if (method.contains('chase') || description.contains('chase')) {
      logoPath = 'assets/logos/chase.svg';
    } else if (method.contains('stanbic') || description.contains('stanbic')) {
      logoPath = 'assets/logos/stanbic.svg';
    } else if (method.contains('standard chartered') || description.contains('standard chartered')) {
      logoPath = 'assets/logos/standard-chartered.svg';
    } else if (method.contains('ncba') || description.contains('ncba')) {
      logoPath = 'assets/logos/ncba.svg';
    } else if (method.contains('dtb') || description.contains('dtb')) {
      logoPath = 'assets/logos/dtb.svg';
    } else if (method.contains('family bank') || description.contains('family bank')) {
      logoPath = 'assets/logos/family-bank.svg';
    } else if (method.contains('im bank') || description.contains('im bank')) {
      logoPath = 'assets/logos/im-bank.svg';
    } else if (method.contains('airtel') || description.contains('airtel')) {
      logoPath = 'assets/logos/airtel.svg';
    } else if (method.contains('tkash') || description.contains('tkash')) {
      logoPath = 'assets/logos/tkash.svg';
    } else if (method.contains('bank of america') || description.contains('bank of america')) {
      logoPath = 'assets/logos/bank-of-america.svg';
    } else if (method.contains('stripe') || description.contains('stripe')) {
      logoPath = 'assets/logos/stripe.svg';
    } else if (method.contains('bank') || description.contains('bank')) {
      logoPath = 'assets/logos/bank.svg';
    }

    if (tx.type == 'deposit') {
      icon = LucideIcons.arrowDownLeft;
      color = AppColors.success;
    } else if (tx.type == 'withdrawal') {
      icon = LucideIcons.arrowUpRight;
      color = AppColors.error;
    } else {
      final theme = Theme.of(context);
      icon = isPositive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
      color = isPositive ? AppColors.success : theme.colorScheme.primary;
    }

    if (isTransfer && (profilePhotoUrl != null || initials != null)) {
      final theme = Theme.of(context);
      return CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.1),
        backgroundImage: profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
        child: profilePhotoUrl == null ? Text(
          initials ?? '',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
        ) : null,
      );
    }

    final iconWidget = logoPath != null 
        ? SvgPicture.asset(
            logoPath, 
            width: 18, 
            height: 18, 
            placeholderBuilder: (BuildContext context) => Icon(icon, color: color, size: 18),
          )
        : Icon(icon, color: color, size: 18);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: color == AppColors.success 
          ? iconWidget.animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 4.seconds, curve: Curves.linear)
          : iconWidget,
    );
  }

  String _getTransactionTitle(VaultTransaction tx) {
    if (tx.type == 'deposit') return 'Deposit via ${tx.method?.toUpperCase() ?? "Bank"}';
    if (tx.type == 'withdrawal') return 'Withdrawal';
    if (tx.type == 'transfer') {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (tx.senderId == currentUserId) {
        return 'Sent to ${tx.receiverProfile?.firstName ?? "User"}';
      } else {
        return 'Received from ${tx.senderProfile?.firstName ?? "User"}';
      }
    }
    return 'Transaction';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildGreeting(BuildContext context, VaultUser user) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '🌅';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $emoji',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.firstName ?? 'Vault User',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AIInsightCard extends StatefulWidget {
  final String? initialInsight;
  const _AIInsightCard({this.initialInsight});

  @override
  State<_AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<_AIInsightCard> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _rotationController.repeat();
    HapticFeedback.lightImpact();

    try {
      context.read<DashboardBloc>().add(RefreshAIInsight());
      await Future.delayed(const Duration(milliseconds: 1200));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final insight = state is DashboardLoaded ? state.latestInsight : widget.initialInsight;

        return GlassCard(
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'AI INSIGHT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _handleRefresh,
                    child: RotationTransition(
                      turns: _rotationController,
                      child: Icon(
                        LucideIcons.refreshCw,
                        size: 16,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight ?? 'Analyzing your financial patterns... Check back soon for pro-active tips!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
