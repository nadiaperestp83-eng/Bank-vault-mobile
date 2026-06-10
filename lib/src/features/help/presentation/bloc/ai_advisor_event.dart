import 'package:equatable/equatable.dart';
import '../../../../models/ai_advisor_model.dart';

abstract class AiAdvisorEvent extends Equatable {
  const AiAdvisorEvent();
  @override
  List<Object?> get props => [];
}

class FetchChatRequested extends AiAdvisorEvent {}

class ChatUpdated extends AiAdvisorEvent {
  final List<AiChatMessage> messages;
  const ChatUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}

class SendMessageRequested extends AiAdvisorEvent {
  final String text;
  const SendMessageRequested(this.text);
  @override
  List<Object?> get props => [text];
}

class ClearChatRequested extends AiAdvisorEvent {}
