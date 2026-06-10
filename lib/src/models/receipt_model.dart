import 'package:equatable/equatable.dart';

class VaultReceipt extends Equatable {
  final String id;
  final String userId;
  final String transactionId;
  final String receiptNumber;
  final double amount;
  final String currency;
  final Map<String, dynamic> transactionDetails;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const VaultReceipt({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.receiptNumber,
    required this.amount,
    required this.currency,
    required this.transactionDetails,
    required this.metadata,
    required this.createdAt,
  });

  factory VaultReceipt.fromJson(Map<String, dynamic> json) {
    return VaultReceipt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionId: json['transaction_id'] as String,
      receiptNumber: json['receipt_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      transactionDetails: json['transaction_details'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_id': transactionId,
      'receipt_number': receiptNumber,
      'amount': amount,
      'currency': currency,
      'transaction_details': transactionDetails,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        transactionId,
        receiptNumber,
        amount,
        currency,
        transactionDetails,
        metadata,
        createdAt,
      ];
}
