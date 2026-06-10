import 'package:equatable/equatable.dart';

class AiChatMessage extends Equatable {
  final String id;
  final String userId;
  final String sender; // 'user' or 'advisor'
  final String text;
  final DateTime createdAt;

  const AiChatMessage({
    required this.id,
    required this.userId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      sender: json['sender'] ?? 'user',
      text: json['text'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'sender': sender,
      'text': text,
    };
  }

  @override
  List<Object?> get props => [id, userId, sender, text, createdAt];
}
