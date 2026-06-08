import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'dart:ui';

class TransactScreen extends StatefulWidget {
  const TransactScreen({super.key});

  @override
  State<TransactScreen> createState() => _TransactScreenState();
}

class _TransactScreenState extends State<TransactScreen> {
  int _activeTab = 0; // 0: Send, 1: Deposit, 2: Withdraw

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64), // Space for VaultTopNav
              _buildModeToggle(),
              const SizedBox(height: 32),
              _buildActiveSection(),
              const SizedBox(height: 40),
              _buildTransactionHistory(),
              const SizedBox(height: 100), // Space for bottom dock
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleItem(0, 'Send'),
            _toggleItem(1, 'Deposit'),
            _toggleItem(2, 'Withdraw'),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(int index, String label) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeTab) {
      case 0:
        return _buildSendSection();
      case 1:
        return _buildDepositSection();
      case 2:
        return _buildWithdrawSection();
      default:
        return const SizedBox();
    }
  }

  // --- SEND SECTION ---
  Widget _buildSendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildProviderCard(LucideIcons.user, 'Vault User', true),
            const SizedBox(width: 12),
            _buildProviderCard(LucideIcons.landmark, 'Bank', false),
            const SizedBox(width: 12),
            _buildProviderCard(LucideIcons.smartphone, 'Mobile Money', false),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Recent Recipients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildContactAvatar('Add', null, isAdd: true),
              _buildContactAvatar('Nevy', 'NV'),
              _buildContactAvatar('Sarah', 'SR'),
              _buildContactAvatar('Elena', 'EL'),
              _buildContactAvatar('Mike', 'MK'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildAmountCard('Send Amount'),
        const SizedBox(height: 32),
        _buildActionBtn('Send Now'),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildProviderCard(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar(String name, String? initials, {bool isAdd = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isAdd ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            child: isAdd 
                ? const Icon(LucideIcons.plus, color: AppColors.primary)
                : Text(initials!, style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- DEPOSIT SECTION ---
  Widget _buildDepositSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deposit Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSourceChip('Mobile Money', true),
            _buildSourceChip('Bank', false),
            _buildSourceChip('Card', false),
          ],
        ),
        const SizedBox(height: 32),
        _buildAmountCard('Deposit Amount'),
        const SizedBox(height: 32),
        _buildSettlementBox(),
        const SizedBox(height: 32),
        _buildActionBtn('Deposit Now'),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSourceChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettlementBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Equivalent Credit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('KES 0.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }

  // --- WITHDRAW SECTION ---
  Widget _buildWithdrawSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildChannelSelector(),
        const SizedBox(height: 32),
        _buildAmountCard('Withdraw Amount'),
        const SizedBox(height: 32),
        _buildSummaryFees(),
        const SizedBox(height: 32),
        _buildActionBtn('Confirm Withdrawal'),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildChannelSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.building, color: AppColors.textSecondaryLight, size: 20),
          SizedBox(width: 12),
          Text('Select Bank / Account', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
          Spacer(),
          Icon(LucideIcons.chevronDown, color: AppColors.textSecondaryLight, size: 18),
        ],
      ),
    );
  }

  Widget _buildSummaryFees() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _summaryRow('Withdrawal Amount', 'KES 0.00'),
          const SizedBox(height: 12),
          _summaryRow('Platform Fee', 'KES 0.00', isRed: true),
          const Divider(height: 32),
          _summaryRow('Total Deduction', 'KES 0.00', isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isRed = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isRed ? Colors.red : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // --- SHARED WIDGETS ---
  Widget _buildAmountCard(String label) {
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
              Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              const Text('Balance: KES 12,450', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: 'KES ',
              prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimaryLight),
              hintText: '0.00',
              hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(0.4),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transaction Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Icon(LucideIcons.search, size: 18, color: Colors.black.withOpacity(0.4)),
          ],
        ),
        const SizedBox(height: 20),
        _buildFilters(),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const Divider(height: 32, thickness: 0.5),
          itemBuilder: (context, index) {
            final transactions = [
              {'type': 'P2P', 'title': 'Transfer to @nevy', 'time': 'Today, 2:30 PM', 'amount': '- KES 2,500', 'isCredit': false},
              {'type': 'DEP', 'title': 'M-Pesa Deposit', 'time': 'Yesterday, 10:15 AM', 'amount': '+ KES 5,000', 'isCredit': true},
              {'type': 'WTH', 'title': 'Withdrawal to KCB', 'time': 'Jun 5, 4:00 PM', 'amount': '- KES 10,000', 'isCredit': false},
              {'type': 'P2P', 'title': 'Received from @elena', 'time': 'Jun 4, 9:20 AM', 'amount': '+ KES 1,500', 'isCredit': true},
            ];
            final tx = transactions[index];
            return Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tx['type'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
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
                        fontSize: 14,
                        color: tx['isCredit'] as bool ? Colors.green : Colors.red,
                      ),
                    ),
                    const Text('KES 12,450', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Transfers', 'Deposits', 'Withdrawals'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          bool isSelected = f == 'All';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (v) {},
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
    );
  }
}
