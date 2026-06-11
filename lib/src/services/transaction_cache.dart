import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_models.dart';

class TransactionCache {
  static const String _keyTransactionHistory = 'transaction_history_cache';

  Future<void> saveTransactionHistory(List<VaultTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString(_keyTransactionHistory, jsonEncode(data));
  }

  Future<List<VaultTransaction>?> getCachedTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_keyTransactionHistory);
    if (cachedStr == null) return null;

    try {
      final List<dynamic> data = jsonDecode(cachedStr);
      return data.map((tx) => VaultTransaction.fromJson(tx)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTransactionHistory);
  }
}
