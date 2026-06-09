import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_models.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Module 1: Identity & Profile
  Future<VaultUser> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    var user = VaultUser.fromJson(response);

    // Module 1: Default Currency Detection
    if (response['primary_currency'] == null) {
      String detectedCurrency = 'USD';
      if (user.country == 'Kenya') detectedCurrency = 'KES';
      else if (user.country == 'UK') detectedCurrency = 'GBP';
      else if (user.country == 'Europe') detectedCurrency = 'EUR';

      // Update local object
      user = VaultUser.fromJson({...response, 'primary_currency': detectedCurrency});
    }
    
    return user;
  }

  // Module 2: Real-time Wallet & Currency Engine
  Future<Map<String, double>> getCurrencyRates() async {
    try {
      final response = await _supabase.from('currency_rates').select();
      final Map<String, double> rates = {};
      if (response != null) {
        for (var row in (response as List)) {
          final code = row['code'] as String?;
          final rate = row['rate'] as num?;
          if (code != null && rate != null) {
            rates[code] = rate.toDouble();
          }
        }
      }
      return rates;
    } catch (e) {
      // Fallback rates if table doesn't exist or error occurs
      return {'USD': 1.0, 'KES': 130.0};
    }
  }

  Stream<Wallet> getWalletStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) {
            // Return a default wallet or handle empty state
            return Wallet(
              id: '',
              userId: userId,
              balance: 0.0,
              currency: 'USD',
              updatedAt: DateTime.now(),
            );
          }
          return Wallet.fromJson(data.first);
        });
  }

  Future<List<BalanceHistory>> getBalanceHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final walletResponse = await _supabase
        .from('wallets')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (walletResponse == null) return [];
    
    final walletId = walletResponse['id'];

    final response = await _supabase
        .from('balance_history')
        .select()
        .eq('wallet_id', walletId)
        .order('recorded_at', ascending: false)
        .limit(90); // Fetch 90 days for better analytics

    return (response as List).map((json) => BalanceHistory.fromJson(json)).toList();
  }

  Map<String, dynamic> calculatePortfolioGrowth(List<BalanceHistory> history) {
    if (history.isEmpty) {
      return {
        'growth': 0.0,
        'trend': 'neutral',
        'history': <double>[],
        'avg30': 0.0,
        'avg60': 0.0
      };
    }

    final historyBalances = history.map((e) => e.balance).toList().reversed.toList();

    // Calculate 30-day average
    final last30Days = history.take(30).toList();
    final avg30 = last30Days.isEmpty 
        ? 0.0 
        : last30Days.map((e) => e.balance).reduce((a, b) => a + b) / last30Days.length;

    // Calculate previous 30-day average (for 60-day trend)
    final prev30Days = history.skip(30).take(30).toList();
    final avg60 = prev30Days.isEmpty 
        ? avg30 
        : prev30Days.map((e) => e.balance).reduce((a, b) => a + b) / prev30Days.length;

    double growth = 0.0;
    String trend = 'neutral';

    if (avg60 > 0) {
      growth = ((avg30 - avg60) / avg60) * 100;
      if (growth > 0.5) trend = 'positive';
      if (growth < -0.5) trend = 'negative';
    }

    return {
      'growth': growth,
      'trend': trend,
      'history': historyBalances,
      'avg30': avg30,
      'avg60': avg60,
    };
  }

  // Module 3: The Unified Ledger (Transactions)
  Future<List<VaultTransaction>> getTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('transactions')
        .select('''
          *,
          sender_profile:profiles!transactions_sender_id_fkey(*),
          receiver_profile:profiles!transactions_receiver_id_fkey(*)
        ''')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    if (response == null) return [];
    return (response as List).map((json) => VaultTransaction.fromJson(json)).toList();
  }

  // Module 4: AI Insights & Proactive Alerts
  Future<Map<String, dynamic>> triggerFinancialHealthCheck() async {
    try {
      final response = await _supabase.functions.invoke('financial-health-check');
      return response.data ?? {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<String?> getLatestFinancialInsight() async {
    final response = await _supabase
        .from('financial_insights')
        .select('content')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response?['content'] as String?;
  }

  Stream<List<VaultNotification>> getNotificationStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .where((json) => json['is_read'] == false)
            .map((json) => VaultNotification.fromJson(json))
            .toList());
  }

  // Module 5: Social & Quick Actions
  Future<List<VaultUser>> getFrequentContacts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('transactions')
        .select('receiver_id')
        .eq('sender_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    if (response == null) return [];

    final receiverIds = (response as List)
        .where((t) => t['receiver_id'] != null)
        .map((t) => t['receiver_id'] as String)
        .toSet()
        .take(4)
        .toList();

    if (receiverIds.isEmpty) return [];

    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', receiverIds);

    if (profilesResponse == null) return [];
    return (profilesResponse as List).map((json) => VaultUser.fromJson(json)).toList();
  }

  Future<List<VaultUser>> getSuggestedUsers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Supabase doesn't have a direct 'random' select, using a simple query excluding self
    final response = await _supabase
        .from('profiles')
        .select()
        .neq('id', userId)
        .limit(8);

    if (response == null) return [];
    return (response as List).map((json) => VaultUser.fromJson(json)).toList();
  }
}
