import 'package:equatable/equatable.dart';
import '../../../../models/ai_advisor_model.dart';

abstract class AiAdvisorState extends Equatable {
  const AiAdvisorState();
  @override
  List<Object?> get props => [];
}

class AiAdvisorInitial extends AiAdvisorState {}

class AiAdvisorLoading extends AiAdvisorState {}

class AiAdvisorLoaded extends AiAdvisorState {
  final List<AiChatMessage> messages;
  final bool isTyping;
  final String? error;

  const AiAdvisorLoaded({
    required this.messages,
    this.isTyping = false,
    this.error,
  });

  @override
  List<Object?> get props => [messages, isTyping, error];
}

class AiAdvisorError extends AiAdvisorState {
  final String message;
  const AiAdvisorError(this.message);
  @override
  List<Object?> get props => [message];
}
