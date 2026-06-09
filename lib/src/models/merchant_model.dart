import 'package:equatable/equatable.dart';

class Merchant extends Equatable {
  final String id;
  final String userId;
  final String businessName;
  final String businessType;
  final bool isActive;

  const Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    required this.isActive,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String? ?? '',
      businessType: json['business_type'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_type': businessType,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, userId, businessName, businessType, isActive];
}
