import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Credit Line', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanRequestSection(),
            const SizedBox(height: 24),
            _buildEligibilityGuard(),
            const SizedBox(height: 24),
            _buildRepaymentTracker(),
            const SizedBox(height: 32),
            const FinanceLedger(
              transactions: [
                {'date': 'Jun 1', 'source': 'Vault Loan', 'type': 'Disbursement', 'amount': '+ KES 50,000'},
                {'date': 'Jun 8', 'source': 'M-Pesa', 'type': 'Repayment', 'amount': '- KES 5,450'},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanRequestSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request New Loan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          // Amount Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixText: 'KES ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                hintText: '0.00',
              ),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          // Period Selector
          const Text('Repayment Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) {
                bool isSelected = _selectedPeriod == period;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = period),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF334155) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF334155) : Colors.black.withOpacity(0.1)),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155).withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155).withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Principal', '50,000'),
                _buildSummaryItem('Interest', '2,500', color: Colors.green),
                _buildSummaryItem('Fees', '0'),
                _buildSummaryItem('Total', '52,500', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color, bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilityGuard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Verified', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEligibilityItem('Account Age', 'Over 6 Months', true),
          const SizedBox(height: 12),
          _buildEligibilityItem('Avg. Deposits', 'KES 15,000+', true),
          const SizedBox(height: 12),
          _buildEligibilityItem('Credit Score', 'Good (720)', true),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Max Limit', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              const Text('KES 150,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityItem(String label, String value, bool isMet) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? AppColors.primary : Colors.grey.withOpacity(0.3),
            boxShadow: isMet ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8)] : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildRepaymentTracker() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF334155), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Loan Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Repayment Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Text('45%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.45,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrackerMetric('Original Amount', 'KES 50,000'),
              _buildTrackerMetric('Repaid', 'KES 22,500'),
              _buildTrackerMetric('Due Date', 'Jul 15'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => PaymentSourceSelector.show(context, 'Repay Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
              elevation: 0,
            ),
            child: const Text('Repay Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
