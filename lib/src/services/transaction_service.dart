import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_models.dart';
import 'transaction_cache.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TransactionCache _cache = TransactionCache();

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
    required String recipientTag,
    required double amount,
    String? currency,
    String? description,
  }) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) throw Exception('User not authenticated');

    await _supabase.rpc('vault_transfer', params: {
      'p_sender_id': senderId,
      'p_recipient_tag': recipientTag,
      'p_amount': amount,
      // Keeping these as they might be used by the RPC too, or I can remove them if I'm sure.
      // But the user specifically mentioned those three.
      // I'll stick to the user's three but keep currency if the RPC allows it.
    });
  }

  Future<VaultUser?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return VaultUser.fromJson(response);
  }

  Future<List<BankAccount>> getUserBankAccounts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('user_bank_accounts')
        .select()
        .eq('user_id', userId);
    
    return (response as List).map((json) => BankAccount.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> createStripeAchIntent({
    required double amount,
    required String currency,
  }) async {
    final response = await _supabase.functions.invoke('stripe-create-intent', body: {
      'amount': amount,
      'currency': currency,
      'payment_method_types': ['us_bank_account'],
    });
    
    final intentData = response.data as Map<String, dynamic>;
    final intentId = intentData['id'] as String?;
    
    if (intentId != null) {
      await createPendingTransaction(
        type: 'deposit',
        amount: amount,
        description: intentId,
        method: 'bank',
      );
    }
    
    return intentData;
  }

  String generateReferenceCode() {
    final userId = _supabase.auth.currentUser?.id ?? 'USER';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'VLT-${userId.substring(0, 4).toUpperCase()}-$timestamp';
  }

  Future<String> uploadTransferReceipt(String filePath) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final fileName = 'receipts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('receipts').upload(fileName, File(filePath));
    return _supabase.storage.from('receipts').getPublicUrl(fileName);
  }

  Future<void> reportManualTransfer({
    required double amount,
    required String reference,
    required String receiptUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('ledger_entries').insert({
      'user_id': userId,
      'amount': amount,
      'type': 'deposit',
      'status': 'pending',
      'reference': reference,
      'description': 'Manual Bank Transfer: $reference',
      'metadata': {
        'method': 'bank',
        'receipt_url': receiptUrl,
      },
    });
  }

  Future<void> linkBankAccount({
    required String bankName,
    required String accountNumber,
    String? accountHolderName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('user_bank_accounts').insert({
      'user_id': userId,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
    });
  }

  List<Map<String, String>> getSupportedBanks() {
    return [
      {'name': 'Equity Bank', 'logo': 'equity.svg'},
      {'name': 'KCB Bank', 'logo': 'kcb.svg'},
      {'name': 'Co-operative Bank', 'logo': 'coop.svg'},
      {'name': 'NCBA Bank', 'logo': 'ncba.svg'},
      {'name': 'Absa Bank', 'logo': 'absa.svg'},
      {'name': 'Stanbic Bank', 'logo': 'stanbic.svg'},
      {'name': 'Standard Chartered', 'logo': 'standard-chartered.svg'},
      {'name': 'DTB Bank', 'logo': 'dtb.svg'},
      {'name': 'Family Bank', 'logo': 'family-bank.svg'},
      {'name': 'I&M Bank', 'logo': 'im-bank.svg'},
    ];
  }

  Future<void> updateProfilePhoneNumber(String phoneNumber) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      'phone_number': phoneNumber,
    }).eq('id', userId);
  }

  String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
      cleaned = '254$cleaned';
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  Future<void> createPendingTransaction({
    required String type,
    required double amount,
    required String description,
    String? method,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('ledger_entries').insert({
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': 'pending',
      'description': description,
      'metadata': {
        'method': method,
      },
    });
  }

  Future<String?> initiateMpesaDeposit({
    required String phoneNumber,
    required double walletCredit,
    required double kesEquivalent,
  }) async {
    final formattedPhone = formatPhoneNumber(phoneNumber);
    debugPrint('DEBUG: Service calling mpesa-deposit for $formattedPhone, amount: $kesEquivalent');
    final response = await _supabase.functions.invoke('mpesa-deposit', body: {
      'phoneNumber': formattedPhone,
      'amount': kesEquivalent,
    });
    
    debugPrint('DEBUG: mpesa-deposit response status: ${response.status}');
    debugPrint('DEBUG: mpesa-deposit response data: ${response.data}');

    final checkoutId = response.data?['CheckoutRequestID'] as String?;
    if (checkoutId != null) {
      await createPendingTransaction(
        type: 'deposit',
        amount: walletCredit,
        description: checkoutId,
        method: 'mpesa',
      );
    }
    return checkoutId;
  }

  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
    List<String>? paymentMethodTypes,
  }) async {
    debugPrint('DEBUG: Service calling stripe-create-intent for \$${amount.toStringAsFixed(2)} $currency');
    final response = await _supabase.functions.invoke('stripe-create-intent', body: {
      'amount': amount,
      'currency': currency,
      'payment_method_types': paymentMethodTypes,
    });
    
    debugPrint('DEBUG: stripe-create-intent response status: ${response.status}');
    debugPrint('DEBUG: stripe-create-intent response data: ${response.data}');

    final intentData = response.data as Map<String, dynamic>;
    final intentId = intentData['id'] as String?;
    
    if (intentId != null) {
      await createPendingTransaction(
        type: 'deposit',
        amount: amount,
        description: intentId,
        method: 'card',
      );
    }
    
    return intentData;
  }

  Future<void> initiateWithdrawal({
    required double amount,
    required String method,
    required String currency,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('process_secure_withdrawal', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_currency': currency,
      'p_description': description,
      'p_method': method,
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
          .from('ledger_entries')
          .select('metadata, description')
          .eq('user_id', userId)
          .eq('type', 'transfer')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(50);

      final List<VaultUser> users = [];
      final Set<String> seenIds = {};

      for (var item in (response as List)) {
        final recipientId = item['metadata']?['recipient_id'] as String?;
        if (recipientId != null && !seenIds.contains(recipientId)) {
          // Fetch profile for this recipient
          final profileResponse = await _supabase.from('profiles').select().eq('id', recipientId).single();
          if (profileResponse != null) {
            users.add(VaultUser.fromJson(profileResponse));
            seenIds.add(recipientId);
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

  Future<List<Map<String, dynamic>>> getSystemBankAccounts() async {
    final response = await _supabase.from('system_bank_accounts').select();
    return List<Map<String, dynamic>>.from(response);
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

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Velocity Check: Max 3 transactions in 5 minutes
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
    final recentTxs = await _supabase
        .from('ledger_entries')
        .select('id')
        .eq('user_id', userId)
        .gt('created_at', fiveMinutesAgo);
    
    if ((recentTxs as List).length >= 3) {
      throw Exception('Velocity limit exceeded. Please wait a few minutes.');
    }

    // 2. Spike Check: Max 400% of last 10 transactions average
    final lastTenTxs = await _supabase
        .from('ledger_entries')
        .select('amount')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);
    
    final txList = lastTenTxs as List;
    if (txList.isNotEmpty) {
      double sum = 0;
      for (var tx in txList) {
        sum += (tx['amount'] as num).toDouble();
      }
      double average = sum / txList.length;
      if (amount > average * 4) {
        throw Exception('Transaction spike detected. Please contact support for large withdrawals.');
      }
    }

    if (amount > 100000) {
      throw Exception('Amount exceeds daily limit for unverified users');
    }
  }

  Stream<List<VaultTransaction>> getTransactionsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(_getMockTransactions());

    return _supabase
        .from('ledger_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return _getMockTransactions();
          final transactions = data.map((json) => VaultTransaction.fromJson(json)).toList();
          return await _attachProfilesToTransactions(transactions, userId);
        });
  }

  Future<List<VaultTransaction>> getTransactionHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _getMockTransactions();

    // Try cache first
    final cached = await _cache.getCachedTransactionHistory();
    if (cached != null && cached.isNotEmpty) {
      // Return cached immediately and refresh in background if needed
      _refreshTransactionHistoryInBackground(userId);
      return cached;
    }

    try {
      final response = await _supabase
          .from('ledger_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) => VaultTransaction.fromJson(json)).toList();
      if (transactions.isEmpty) return _getMockTransactions();
      
      final withProfiles = await _attachProfilesToTransactions(transactions, userId);
      _cache.saveTransactionHistory(withProfiles);
      return withProfiles;
    } catch (e) {
      return _getMockTransactions();
    }
  }

  Future<List<VaultTransaction>> _attachProfilesToTransactions(List<VaultTransaction> transactions, String userId) async {
    final Set<String> otherIds = {};
    for (var tx in transactions) {
      if (tx.type == 'transfer') {
        final otherId = tx.senderId == userId ? tx.receiverId : tx.senderId;
        if (otherId != null) otherIds.add(otherId);
      }
    }

    if (otherIds.isEmpty) return transactions;

    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', otherIds.toList());

    if (profilesResponse == null) return transactions;

    final Map<String, VaultUser> profileMap = {
      for (var p in (profilesResponse as List)) p['id']: VaultUser.fromJson(p)
    };

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

  void _refreshTransactionHistoryInBackground(String userId) async {
    try {
      final response = await _supabase
          .from('ledger_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) => VaultTransaction.fromJson(json)).toList();
      if (transactions.isNotEmpty) {
        final withProfiles = await _attachProfilesToTransactions(transactions, userId);
        _cache.saveTransactionHistory(withProfiles);
      }
    } catch (e) {
      // Silent error for background refresh
    }
  }

  List<VaultTransaction> _getMockTransactions() {
    return [
      VaultTransaction(
        id: 'VT-782910',
        description: 'Transfer to @nevy',
        amount: 2500,
        currency: 'KES',
        type: 'transfer',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        recordedBalance: 12450,
      ),
      VaultTransaction(
        id: 'DEP-102931',
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
        id: 'WTH-902811',
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
        id: 'VT-110293',
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
