import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String userId;
  final bool biometricEnabled;
  final bool notificationsTransferReceived;
  final bool notificationsAccountLogin;
  final bool notificationsTransferSent;
  final bool notificationsAiInsights;
  final String theme;
  final String language;

  const UserPreferences({
    required this.userId,
    required this.biometricEnabled,
    required this.notificationsTransferReceived,
    required this.notificationsAccountLogin,
    required this.notificationsTransferSent,
    required this.notificationsAiInsights,
    required this.theme,
    required this.language,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] as String,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      notificationsTransferReceived: json['notifications_transfer_received'] as bool? ?? true,
      notificationsAccountLogin: json['notifications_account_login'] as bool? ?? true,
      notificationsTransferSent: json['notifications_transfer_sent'] as bool? ?? true,
      notificationsAiInsights: json['notifications_ai_insights'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'biometric_enabled': biometricEnabled,
      'notifications_transfer_received': notificationsTransferReceived,
      'notifications_account_login': notificationsAccountLogin,
      'notifications_transfer_sent': notificationsTransferSent,
      'notifications_ai_insights': notificationsAiInsights,
      'theme': theme,
      'language': language,
    };
  }

  UserPreferences copyWith({
    bool? biometricEnabled,
    bool? notificationsTransferReceived,
    bool? notificationsAccountLogin,
    bool? notificationsTransferSent,
    bool? notificationsAiInsights,
    String? theme,
    String? language,
  }) {
    return UserPreferences(
      userId: userId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsTransferReceived: notificationsTransferReceived ?? this.notificationsTransferReceived,
      notificationsAccountLogin: notificationsAccountLogin ?? this.notificationsAccountLogin,
      notificationsTransferSent: notificationsTransferSent ?? this.notificationsTransferSent,
      notificationsAiInsights: notificationsAiInsights ?? this.notificationsAiInsights,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        biometricEnabled,
        notificationsTransferReceived,
        notificationsAccountLogin,
        notificationsTransferSent,
        notificationsAiInsights,
        theme,
        language,
      ];
}
