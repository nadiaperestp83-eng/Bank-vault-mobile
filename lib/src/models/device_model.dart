import 'package:equatable/equatable.dart';

class UserDevice extends Equatable {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final DateTime lastActive;
  final bool isActive;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.lastActive,
    required this.isActive,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      deviceType: json['device_type'] as String? ?? 'unknown',
      lastActive: DateTime.parse(json['last_active'] as String? ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'last_active': lastActive.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, userId, deviceName, deviceType, lastActive, isActive];
}
