import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/common_widgets/glass_card.dart';
import 'package:vault_os/src/features/finance/presentation/widgets/finance_ledger.dart';
import 'package:vault_os/src/features/finance/presentation/widgets/payment_source_selector.dart';

class LoansDashboardScreen extends StatefulWidget {
  const LoansDashboardScreen({super.key});

  @override
  State<LoansDashboardScreen> createState() => _LoansDashboardScreenState();
}

class _LoansDashboardScreenState extends State<LoansDashboardScreen> {
  String _selectedPeriod = '6 Months';
  final List<String> _periods = ['1 Month', '3 Months', '6 Months', '12 Months'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'Credit Line', 
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

                _buildEligibilityGuard(context),
                const SizedBox(height: 24),
                
                _buildLoanRequestSection(context),
                const SizedBox(height: 24),
                
                _buildRepaymentTracker(context),
                const SizedBox(height: 32),
                
                Text(
                  'CREDIT HISTORY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                
                const FinanceLedger(
                  transactions: [
                    {'date': 'Jun 1', 'source': 'Vault Loan', 'type': 'Disbursement', 'amount': '+ KES 50,000'},
                    {'date': 'Jun 8', 'source': 'M-Pesa', 'type': 'Repayment', 'amount': '- KES 5,450'},
                  ],
                ),
                const SizedBox(height: 120),
              ],
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
          'Capital Access',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),
        Text(
          'Low-interest liquidity backed by your assets.',
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
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.08),
                  const Color(0xFF6366F1).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanRequestSection(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Credit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          
          Text('DESIRED AMOUNT', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Text('KES', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18)),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text('REPAYMENT WINDOW', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) {
                bool isSelected = _selectedPeriod == period;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = period),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(context, 'Principal', '50,000'),
                _buildSummaryItem(context, 'Interest (5%)', '2,500', color: Colors.green),
                _buildSummaryItem(context, 'Total Due', '52,500', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.zap, size: 20),
                SizedBox(width: 10),
                Text('Instant Disbursement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, {Color? color, bool isBold = false}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilityGuard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Eligibility Guard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.checkCircle, color: AppColors.primary, size: 10),
                    SizedBox(width: 4),
                    Text('SECURE', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEligibilityItem('Trust Score', '720 (High)', true),
          const SizedBox(height: 14),
          _buildEligibilityItem('Collateral Ratio', '1:1.5 Coverage', true),
          const SizedBox(height: 14),
          _buildEligibilityItem('Repayment Health', 'Excellent', true),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MAX CREDIT LIMIT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('KES 150,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityItem(String label, String value, bool isMet) {
    return Row(
      children: [
        Icon(isMet ? LucideIcons.shieldCheck : LucideIcons.circle, color: isMet ? AppColors.primary : Colors.grey, size: 16),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRepaymentTracker(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.activity, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Active Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('REPAYMENT PROGRESS', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const Text('45%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.45,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrackerMetric('REMAINING', 'KES 30,000'),
              _buildTrackerMetric('NEXT DUE', '15 JUL'),
              _buildTrackerMetric('INSTALMENT', 'KES 5,450'),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => PaymentSourceSelector.show(context, 'Repay Credit Line', (source) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Repayment processed via $source'),
                  backgroundColor: AppColors.success,
                ),
              );
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              elevation: 0,
            ),
            child: const Text('Execute Repayment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
