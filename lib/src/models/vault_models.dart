import 'package:equatable/equatable.dart';

class VaultUser extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String? kycStatus;
  final String? kycTag;
  final String primaryCurrency;
  final String? pinHash;
  final String? country;
  final bool biometricEnabled;

  VaultUser({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.kycStatus,
    this.kycTag,
    required this.primaryCurrency,
    this.pinHash,
    this.country,
    this.biometricEnabled = false,
  });

  factory VaultUser.fromJson(Map<String, dynamic> json) {
    return VaultUser(
      id: json['id'] ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      kycStatus: json['kyc_status']?.toString(),
      kycTag: json['kyc_tag'] as String?,
      primaryCurrency: json['primary_currency'] ?? 'KES',
      pinHash: json['pin_hash'] as String?,
      country: json['country'] as String?,
      biometricEnabled: json['biometric_enabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'kyc_status': kycStatus,
      'kyc_tag': kycTag,
      'primary_currency': primaryCurrency,
      'pin_hash': pinHash,
      'country': country,
      'biometric_enabled': biometricEnabled,
    };
  }

  String get fullName {
    if (firstName == null && lastName == null) return 'Vault User';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
  
  bool get hasPin => pinHash != null;

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phoneNumber,
        profilePhotoUrl,
        kycStatus,
        kycTag,
        primaryCurrency,
        pinHash,
        country,
        biometricEnabled,
      ];
}

class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double getBalanceIn(String targetCurrency, double conversionRate) {
    if (currency == targetCurrency) return balance;
    if (currency == 'USD' && targetCurrency == 'KES') return balance * conversionRate;
    if (currency == 'KES' && targetCurrency == 'USD') return balance / conversionRate;
    return balance;
  }

  @override
  List<Object?> get props => [id, userId, balance, currency, updatedAt];
}

class BankAccount extends Equatable {
  final String id;
  final String userId;
  final String bankName;
  final String accountNumber;
  final String? accountHolderName;
  final String? routingNumber;
  final String? logoUrl;
  final String? stripeBankAccountId;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountNumber,
    this.accountHolderName,
    this.routingNumber,
    this.logoUrl,
    this.stripeBankAccountId,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      userId: json['user_id'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      accountHolderName: json['account_holder_name'],
      routingNumber: json['routing_number'],
      logoUrl: json['logo_url'],
      stripeBankAccountId: json['stripe_bank_account_id'],
    );
  }

  @override
  List<Object?> get props => [id, userId, bankName, accountNumber, accountHolderName, routingNumber, logoUrl, stripeBankAccountId];
}

class LedgerEntry extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final String? reference;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  LedgerEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.reference,
    this.description,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      type: json['type'] ?? '',
      status: json['status'] ?? 'completed',
      reference: json['reference'],
      description: json['description'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': status,
      'reference': reference,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, amount, currency, type, status, reference, description, metadata, createdAt, updatedAt];
}

class VaultTransaction extends Equatable {
  final String id;
  final String? senderId;
  final String? receiverId;
  final double amount;
  final String currency;
  final String type; // 'transfer', 'deposit', 'withdrawal'
  final String? method;
  final String status;
  final DateTime createdAt;
  final String? description;
  final double? recordedBalance;
  final VaultUser? senderProfile;
  final VaultUser? receiverProfile;

  VaultTransaction({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.amount,
    required this.currency,
    required this.type,
    this.method,
    required this.status,
    required this.createdAt,
    this.description,
    this.recordedBalance,
    this.senderProfile,
    this.receiverProfile,
  });

  factory VaultTransaction.fromJson(Map<String, dynamic> json) {
    return VaultTransaction(
      id: json['id'] ?? '',
      senderId: json['sender_id'] as String? ?? json['user_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      type: json['type'] ?? 'transfer',
      method: json['method'] as String? ?? (json['metadata']?['method'] as String?),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      description: json['description'] as String?,
      recordedBalance: json['recorded_balance'] != null 
          ? (json['recorded_balance'] as num?)?.toDouble() 
          : null,
      senderProfile: json['sender_profile'] != null 
          ? VaultUser.fromJson(json['sender_profile']) 
          : null,
      receiverProfile: json['receiver_profile'] != null 
          ? VaultUser.fromJson(json['receiver_profile']) 
          : null,
    );
  }

  factory VaultTransaction.fromLedger(LedgerEntry ledger) {
    return VaultTransaction(
      id: ledger.reference ?? ledger.id,
      senderId: ledger.userId,
      amount: ledger.amount,
      currency: ledger.currency,
      type: ledger.type,
      method: ledger.metadata['method'] as String?,
      status: ledger.status,
      createdAt: ledger.createdAt,
      description: ledger.description,
      recordedBalance: (ledger.metadata['recorded_balance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'amount': amount,
      'currency': currency,
      'type': type,
      'method': method,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'recorded_balance': recordedBalance,
      'sender_profile': senderProfile?.toJson(),
      'receiver_profile': receiverProfile?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        amount,
        currency,
        type,
        method,
        status,
        createdAt,
        description,
        recordedBalance,
        senderProfile,
        receiverProfile,
      ];
}

class VaultNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'success', 'error'
  final bool isRead;
  final DateTime createdAt;

  VaultNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory VaultNotification.fromJson(Map<String, dynamic> json) {
    return VaultNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == 'true',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, title, message, type, isRead, createdAt];
}

class BalanceHistory extends Equatable {
  final String id;
  final String walletId;
  final double balance;
  final DateTime recordedAt;

  BalanceHistory({
    required this.id,
    required this.walletId,
    required this.balance,
    required this.recordedAt,
  });

  factory BalanceHistory.fromJson(Map<String, dynamic> json) {
    return BalanceHistory(
      id: json['id'] ?? '',
      walletId: json['wallet_id'] ?? '',
      balance: (json['recorded_balance'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recorded_at'] != null 
          ? DateTime.parse(json['recorded_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'recorded_balance': balance,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, walletId, balance, recordedAt];
}

class SavingsGoal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadlineDate;
  final String status; // 'active', 'completed', 'missed'
  final String? automationFrequency; // 'daily', 'weekly', 'monthly'
  final double? automationAmount;
  final bool rewardCredited;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadlineDate,
    required this.status,
    this.automationFrequency,
    this.automationAmount,
    this.rewardCredited = false,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadlineDate: json['deadline_date'] != null 
          ? DateTime.parse(json['deadline_date']) 
          : null,
      status: json['status'] ?? 'active',
      automationFrequency: json['automation_frequency'] as String?,
      automationAmount: (json['automation_amount'] as num?)?.toDouble(),
      rewardCredited: json['reward_credited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline_date': deadlineDate?.toIso8601String(),
      'status': status,
      'automation_frequency': automationFrequency,
      'automation_amount': automationAmount,
      'reward_credited': rewardCredited,
    };
  }

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0.0;
  int get daysRemaining => deadlineDate != null ? deadlineDate!.difference(DateTime.now()).inDays : 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        targetAmount,
        currentAmount,
        deadlineDate,
        status,
        automationFrequency,
        automationAmount,
        rewardCredited,
      ];
}

class SavingsLedgerEntry extends Equatable {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final String source; // 'M-Pesa', 'Vault', etc.
  final String type; // 'manual', 'automated'
  final double runningTotal;
  final DateTime createdAt;

  SavingsLedgerEntry({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    required this.source,
    required this.type,
    required this.runningTotal,
    required this.createdAt,
  });

  factory SavingsLedgerEntry.fromJson(Map<String, dynamic> json) {
    return SavingsLedgerEntry(
      id: json['id'] ?? '',
      goalId: json['goal_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] ?? 'Vault',
      type: json['type'] ?? 'manual',
      runningTotal: (json['running_total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'source': source,
      'type': type,
      'running_total': runningTotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, goalId, userId, amount, source, type, runningTotal, createdAt];
}
