import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String? userId;
  final String actionType;
  final String? ipAddress;
  final String? deviceInfo;
  final String? location;
  final bool isSuspicious;
  final DateTime createdAt;
  final String? nationality;

  const ActivityLog({
    required this.id,
    this.userId,
    required this.actionType,
    this.ipAddress,
    this.deviceInfo,
    this.location,
    this.isSuspicious = false,
    required this.createdAt,
    this.nationality,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      actionType: json['action_type'] as String,
      ipAddress: json['ip_address'] as String?,
      deviceInfo: json['device_info'] as String?,
      location: json['location'] as String?,
      isSuspicious: json['is_suspicious'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      nationality: json['nationality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
      'location': location,
      'is_suspicious': isSuspicious,
      'created_at': createdAt.toIso8601String(),
      'nationality': nationality,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        actionType,
        ipAddress,
        deviceInfo,
        location,
        isSuspicious,
        createdAt,
        nationality,
      ];
}
