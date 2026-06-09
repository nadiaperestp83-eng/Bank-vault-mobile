class VaultUser {
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
  });

  factory VaultUser.fromJson(Map<String, dynamic> json) {
    return VaultUser(
      id: json['id'] ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      kycStatus: json['kyc_status'] as String?,
      kycTag: json['kyc_tag'] as String?,
      primaryCurrency: json['primary_currency'] ?? 'USD',
      pinHash: json['pin_hash'] as String?,
      country: json['country'] as String?,
    );
  }

  String get fullName {
    if (firstName == null && lastName == null) return 'Vault User';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
  
  bool get hasPin => pinHash != null;
}

class Wallet {
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

  double getBalanceIn(String targetCurrency, double conversionRate) {
    if (currency == targetCurrency) return balance;
    if (currency == 'USD' && targetCurrency == 'KES') return balance * conversionRate;
    if (currency == 'KES' && targetCurrency == 'USD') return balance / conversionRate;
    return balance;
  }
}

class VaultTransaction {
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
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      type: json['type'] ?? 'transfer',
      method: json['method'] as String?,
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
}

class VaultNotification {
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
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class BalanceHistory {
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
}
