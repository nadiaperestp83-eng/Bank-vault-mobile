import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_models.dart';

class SavingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // A. Fetching Data (Read Flow)
  Stream<List<SavingsGoal>> watchGoals() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('savings_goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => SavingsGoal.fromJson(json)).toList());
  }

  Stream<List<SavingsLedgerEntry>> watchLedger(String goalId) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('savings_ledger')
        .stream(primaryKey: ['id'])
        .eq('goal_id', goalId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SavingsLedgerEntry.fromJson(json)).toList());
  }

  Future<List<SavingsGoal>> getGoals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('savings_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => SavingsGoal.fromJson(json)).toList();
  }

  Future<List<SavingsLedgerEntry>> getLedger(String goalId) async {
    final response = await _supabase
        .from('savings_ledger')
        .select()
        .eq('goal_id', goalId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => SavingsLedgerEntry.fromJson(json)).toList();
  }

  // B. Creating/Updating Goals (Write Flow)
  Future<void> createGoal(SavingsGoal goal) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Enforce a client-side limit of 2 active goals per user
    final activeGoals = await _supabase
        .from('savings_goals')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active');
    
    if ((activeGoals as List).length >= 2) {
      throw Exception('You can only have 2 active savings goals at a time.');
    }

    await _supabase.from('savings_goals').insert(goal.toJson());
  }

  // C. Making a Contribution (Transaction Flow)
  Future<void> addContribution({
    required SavingsGoal goal,
    required double amount,
    required String source,
    String type = 'manual',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Wallet Deduction (Internal Transfer)
    if (source == 'Vault Balance') {
      final walletResponse = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .single();
      
      final wallet = Wallet.fromJson(walletResponse);
      
      // Currency check (Assume goal is in KES for now as per project defaults)
      double deductionAmount = amount;
      if (wallet.currency == 'USD') {
        // Fetch conversion rate
        final rateResponse = await _supabase
            .from('currency_rates')
            .select('rate')
            .eq('code', 'KES')
            .single();
        final kesRate = (rateResponse['rate'] as num).toDouble();
        deductionAmount = amount / kesRate;
      }

      if (wallet.balance < deductionAmount) {
        throw Exception('Insufficient Vault Balance');
      }

      // Execute UPDATE on wallets
      await _supabase
          .from('wallets')
          .update({'balance': wallet.balance - deductionAmount})
          .eq('id', wallet.id);

      // Create record in main transactions table
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'sender_id': userId,
        'amount': amount,
        'currency': 'KES',
        'type': 'transfer',
        'status': 'completed',
        'description': 'Contribution to ${goal.title}',
      });
    }

    // 2. Savings Ledger Entry
    final newTotal = goal.currentAmount + amount;
    await _supabase.from('savings_ledger').insert({
      'goal_id': goal.id,
      'user_id': userId,
      'amount': amount,
      'source': source,
      'type': type,
      'running_total': newTotal,
    });

    // 3. Goal Progress Update
    await _supabase
        .from('savings_goals')
        .update({'current_amount': newTotal})
        .eq('id', goal.id);
  }
}
