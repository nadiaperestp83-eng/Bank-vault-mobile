import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/vault_models.dart';
import '../models/receipt_model.dart';

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
        .from('ledger_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response == null) return [];
    
    final List<Map<String, dynamic>> rawEntries = List<Map<String, dynamic>>.from(response);
    
    // 1. Map to VaultTransaction initially to extract IDs
    final List<VaultTransaction> transactions = rawEntries.map((json) => VaultTransaction.fromJson(json)).toList();
    
    // 2. Identify unique "other party" IDs
    final Set<String> otherIds = {};
    for (var tx in transactions) {
      if (tx.type == 'transfer') {
        final otherId = tx.senderId == userId ? tx.receiverId : tx.senderId;
        if (otherId != null) otherIds.add(otherId);
      }
    }
    
    // 3. Fetch all required profiles in one go
    if (otherIds.isEmpty) return transactions;
    
    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', otherIds.toList());
        
    if (profilesResponse == null) return transactions;
    
    final Map<String, VaultUser> profileMap = {
      for (var p in (profilesResponse as List)) p['id']: VaultUser.fromJson(p)
    };
    
    // 4. Attach profiles back to transactions
    return transactions.map((tx) {
      if (tx.type == 'transfer') {
        final otherId = tx.senderId == userId ? tx.receiverId : tx.senderId;
        if (otherId != null && profileMap.containsKey(otherId)) {
          final profile = profileMap[otherId];
          return tx.senderId == userId 
              ? tx.copyWith(receiverProfile: profile)
              : tx.copyWith(senderProfile: profile);
        }
      }
      return tx;
    }).toList();
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

    // Combine notifications and activity logs
    final notificationsStream = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    final activityLogsStream = _supabase
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    return Rx.combineLatest2<List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<VaultNotification>>(
      notificationsStream,
      activityLogsStream,
      (notifications, logs) {
        final List<VaultNotification> combined = [];
        
        // Map standard notifications
        combined.addAll(notifications.map((json) => VaultNotification.fromJson(json)));
        
        // Map activity logs to notifications
        combined.addAll(logs.map((log) {
          final actionType = log['action_type'] as String? ?? 'Activity';
          final deviceInfo = log['device_info'] as String? ?? 'Unknown device';
          final location = log['location'] as String? ?? '';
          
          return VaultNotification(
            id: 'log_${log['id']}',
            userId: userId,
            title: actionType,
            message: 'Detected on $deviceInfo ${location.isNotEmpty ? "near $location" : ""}',
            type: (log['is_suspicious'] == true) ? 'warning' : 'info',
            isRead: true, // Activity logs are considered "read" by default for display
            createdAt: DateTime.parse(log['created_at'] as String),
          );
        }));

        // Sort by date descending (newest first)
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Filter and Deduplicate
        final filtered = <VaultNotification>[];
        for (final n in combined) {
          final title = n.title.toLowerCase();

          // Rule 1: Remove "Biometric login" and generic "Login" completely as requested
          if (title.contains('biometric login') || title == 'login') continue;

          // Rule 2: Deduplicate remaining login alerts (e.g., "Account Login") if multiple occur within 10 seconds
          if (title.contains('account login')) {
            final isDuplicate = filtered.any((existing) {
              final existingTitle = existing.title.toLowerCase();
              return existingTitle.contains('account login') &&
                     (existing.createdAt.difference(n.createdAt).inSeconds.abs() < 10);
            });
            if (isDuplicate) continue;
          }

          filtered.add(n);
        }

        return filtered;
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Stream<List<VaultReceipt>> getReceiptsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('receipts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final receipts = data.map((json) => VaultReceipt.fromJson(json)).toList();
          receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return receipts;
        });
  }

  Future<List<VaultReceipt>> getReceipts({int limit = 20, int offset = 0}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => VaultReceipt.fromJson(json)).toList();
  }

  // Module 5: Social & Quick Actions
  Future<List<VaultUser>> getFrequentContacts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Fetch from 'transactions' table to count frequency
    final response = await _supabase
        .from('transactions')
        .select('receiver_id')
        .eq('sender_id', userId)
        .eq('status', 'completed');

    if (response == null || (response as List).isEmpty) return [];

    // 2. Count frequencies of receiver_id
    final Map<String, int> frequencies = {};
    for (var entry in (response as List)) {
      final recipientId = entry['receiver_id'] as String?;
      if (recipientId != null) {
        frequencies[recipientId] = (frequencies[recipientId] ?? 0) + 1;
      }
    }

    if (frequencies.isEmpty) return [];

    // 3. Sort by frequency and take top IDs
    final sortedIds = frequencies.keys.toList()
      ..sort((a, b) => frequencies[b]!.compareTo(frequencies[a]!));
    
    final topIds = sortedIds.take(10).toList();

    // 4. Fetch profiles for these top IDs
    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', topIds);

    if (profilesResponse == null) return [];
    
    final profiles = (profilesResponse as List).map((json) => VaultUser.fromJson(json)).toList();
    
    // Maintain frequency order
    profiles.sort((a, b) => frequencies[b.id]!.compareTo(frequencies[a.id]!));
    
    return profiles;
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
