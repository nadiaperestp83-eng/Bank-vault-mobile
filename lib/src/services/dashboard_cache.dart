import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_models.dart';
import '../models/receipt_model.dart';

class DashboardCache {
  static const String _keyDashboardData = 'dashboard_cache_data';

  Future<void> saveDashboardData({
    required VaultUser user,
    required Wallet wallet,
    required List<VaultTransaction> transactions,
    required Map<String, dynamic> growthData,
    required List<VaultNotification> notifications,
    required List<VaultReceipt> receipts,
    required List<VaultUser> frequentContacts,
    required List<VaultUser> suggestedUsers,
    required Map<String, double> currencyRates,
    String? latestInsight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'user': user.toJson(),
      'wallet': wallet.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'growthData': growthData,
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'receipts': receipts.map((r) => r.toJson()).toList(),
      'frequentContacts': frequentContacts.map((c) => c.toJson()).toList(),
      'suggestedUsers': suggestedUsers.map((u) => u.toJson()).toList(),
      'currencyRates': currencyRates,
      'latestInsight': latestInsight,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_keyDashboardData, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_keyDashboardData);
    if (cachedStr == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(cachedStr);
      
      return {
        'user': VaultUser.fromJson(data['user']),
        'wallet': Wallet.fromJson(data['wallet']),
        'transactions': (data['transactions'] as List)
            .map((t) => VaultTransaction.fromJson(t))
            .toList(),
        'growthData': data['growthData'] as Map<String, dynamic>,
        'notifications': (data['notifications'] as List)
            .map((n) => VaultNotification.fromJson(n))
            .toList(),
        'receipts': (data['receipts'] as List)
            .map((r) => VaultReceipt.fromJson(r))
            .toList(),
        'frequentContacts': (data['frequentContacts'] as List)
            .map((c) => VaultUser.fromJson(c))
            .toList(),
        'suggestedUsers': (data['suggestedUsers'] as List)
            .map((u) => VaultUser.fromJson(u))
            .toList(),
        'currencyRates': (data['currencyRates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        'latestInsight': data['latestInsight'] as String?,
        'cachedAt': DateTime.parse(data['cachedAt']),
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDashboardData);
  }
}
