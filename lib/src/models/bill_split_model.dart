import 'package:equatable/equatable.dart';
import 'vault_models.dart';

class BillSplit extends Equatable {
  final String id;
  final String creatorId;
  final String title;
  final double totalAmount;
  final String category;
  final String status;
  final DateTime createdAt;
  final VaultUser? creatorProfile;
  final List<BillSplitMember> members;

  const BillSplit({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.status,
    required this.createdAt,
    this.creatorProfile,
    this.members = const [],
  });

  factory BillSplit.fromJson(Map<String, dynamic> json) {
    return BillSplit(
      id: json['id']?.toString() ?? '',
      creatorId: json['creator_id'] ?? '',
      title: json['title'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      creatorProfile: json['creator'] != null 
          ? VaultUser.fromJson(json['creator']) 
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => BillSplitMember.fromJson(m))
              .toList()
          : [],
    );
  }

  double get paidAmount {
    return members
        .where((m) => m.status == 'paid')
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  double get pendingAmount => totalAmount - paidAmount;

  @override
  List<Object?> get props => [id, creatorId, title, totalAmount, category, status, createdAt, creatorProfile, members];
}

class BillSplitMember extends Equatable {
  final String id;
  final String splitId;
  final String userId;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final VaultUser? userProfile;

  const BillSplitMember({
    required this.id,
    required this.splitId,
    required this.userId,
    required this.amount,
    required this.status,
    this.paidAt,
    this.userProfile,
  });

  factory BillSplitMember.fromJson(Map<String, dynamic> json) {
    return BillSplitMember(
      id: json['id']?.toString() ?? '',
      splitId: json['split_id']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      userProfile: json['user'] != null ? VaultUser.fromJson(json['user']) : null,
    );
  }

  @override
  List<Object?> get props => [id, splitId, userId, amount, status, paidAt, userProfile];
}
