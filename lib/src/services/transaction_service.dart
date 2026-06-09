import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_models.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyPin(String pin) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('pin_hash')
          .eq('id', userId)
          .single();

      final storedHash = response['pin_hash'] as String?;
      return storedHash == _hashPin(pin);
    } catch (e) {
      return false;
    }
  }

  Future<void> vaultTransfer({
    required String receiverTag,
    required double amount,
    required String currency,
    String? description,
  }) async {
    await _supabase.rpc('vault_transfer', params: {
      'p_receiver_tag': receiverTag,
      'p_amount': amount,
      'p_currency': currency,
      'p_description': description,
    });
  }

  Future<String?> initiateMpesaDeposit({
    required String phoneNumber,
    required double amount,
  }) async {
    final response = await _supabase.functions.invoke('mpesa-deposit', body: {
      'phoneNumber': phoneNumber,
      'amount': amount,
    });
    return response.data?['CheckoutRequestID'] as String?;
  }

  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
  }) async {
    final response = await _supabase.functions.invoke('stripe-create-intent', body: {
      'amount': amount,
      'currency': currency,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> initiateWithdrawal({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    await _supabase.rpc('process_secure_withdrawal', params: {
      'p_amount': amount,
      'p_method': method,
      'p_details': details,
    });
  }

  Future<List<VaultUser>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .or('kyc_tag.ilike.%$query%,first_name.ilike.%$query%,last_name.ilike.%$query%')
        .limit(10);

    return (response as List).map((json) => VaultUser.fromJson(json)).toList();
  }

  Future<List<VaultUser>> getFrequentRecipients() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _getMockRecipients();

    try {
      final response = await _supabase
          .from('transactions')
          .select('receiver_id, profiles!transactions_receiver_id_fkey(*)')
          .eq('sender_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(20);

      final List<VaultUser> users = [];
      final Set<String> seenIds = {};

      for (var item in (response as List)) {
        final profile = item['profiles'];
        if (profile != null) {
          final user = VaultUser.fromJson(profile);
          if (!seenIds.contains(user.id)) {
            users.add(user);
            seenIds.add(user.id);
          }
        }
        if (users.length >= 5) break;
      }
      
      if (users.isEmpty) return _getMockRecipients();
      return users;
    } catch (e) {
      return _getMockRecipients();
    }
  }

  List<VaultUser> _getMockRecipients() {
    return [
      VaultUser(id: '1', firstName: 'Nevy', kycTag: '@nevy', email: 'nevy@vault.com', primaryCurrency: 'KES'),
      VaultUser(id: '2', firstName: 'Sarah', kycTag: '@sarah', email: 'sarah@vault.com', primaryCurrency: 'KES'),
      VaultUser(id: '3', firstName: 'Elena', kycTag: '@elena', email: 'elena@vault.com', primaryCurrency: 'KES'),
      VaultUser(id: '4', firstName: 'Mike', kycTag: '@mike', email: 'mike@vault.com', primaryCurrency: 'KES'),
    ];
  }

  double calculateFee(double amount, String type) {
    if (type == 'withdrawal') {
      return amount * 0.01; // 1% fee
    }
    return 0.0;
  }

  Future<void> evaluateTransaction({
    required double amount,
    required double balance,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }
    if (amount > balance) {
      throw Exception('Insufficient balance');
    }
    if (amount > 100000) {
      throw Exception('Amount exceeds daily limit for unverified users');
    }
  }

  Stream<List<VaultTransaction>> getTransactionsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(_getMockTransactions());

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          if (data.isEmpty) return _getMockTransactions();
          return data.map((json) => VaultTransaction.fromJson(json)).toList();
        });
  }

  Future<List<VaultTransaction>> getTransactionHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _getMockTransactions();

    try {
      final response = await _supabase
          .from('transactions')
          .select('*, sender_profile:profiles!transactions_sender_id_fkey(*), receiver_profile:profiles!transactions_receiver_id_fkey(*)')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) => VaultTransaction.fromJson(json)).toList();
      if (transactions.isEmpty) return _getMockTransactions();
      return transactions;
    } catch (e) {
      return _getMockTransactions();
    }
  }

  List<VaultTransaction> _getMockTransactions() {
    return [
      VaultTransaction(
        id: '1',
        description: 'Transfer to @nevy',
        amount: 2500,
        currency: 'KES',
        type: 'transfer',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        recordedBalance: 12450,
      ),
      VaultTransaction(
        id: '2',
        description: 'M-Pesa Deposit',
        amount: 5000,
        currency: 'KES',
        type: 'deposit',
        method: 'mpesa',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        recordedBalance: 14950,
      ),
      VaultTransaction(
        id: '3',
        description: 'Withdrawal to KCB',
        amount: 10000,
        currency: 'KES',
        type: 'withdrawal',
        method: 'bank',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        recordedBalance: 9950,
      ),
      VaultTransaction(
        id: '4',
        description: 'Received from @elena',
        amount: 1500,
        currency: 'KES',
        type: 'transfer',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        recordedBalance: 19950,
      ),
    ];
  }
}
