import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/ai_advisor_service.dart';
import 'ai_advisor_event.dart';
import 'ai_advisor_state.dart';
import '../../../../models/ai_advisor_model.dart';

class AiAdvisorBloc extends Bloc<AiAdvisorEvent, AiAdvisorState> {
  final AiAdvisorService _aiAdvisorService;
  StreamSubscription<List<AiChatMessage>>? _messagesSubscription;

  AiAdvisorBloc({required AiAdvisorService aiAdvisorService})
      : _aiAdvisorService = aiAdvisorService,
        super(AiAdvisorInitial()) {
    on<FetchChatRequested>(_onFetchChatRequested);
    on<ChatUpdated>(_onChatUpdated);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<ClearChatRequested>(_onClearChatRequested);
  }

  Future<void> _onFetchChatRequested(FetchChatRequested event, Emitter<AiAdvisorState> emit) async {
    emit(AiAdvisorLoading());
    await _messagesSubscription?.cancel();
    _messagesSubscription = _aiAdvisorService.watchMessages().listen(
      (messages) => add(ChatUpdated(messages)),
      onError: (error) => emit(AiAdvisorError(error.toString())),
    );
  }

  void _onChatUpdated(ChatUpdated event, Emitter<AiAdvisorState> emit) {
    emit(AiAdvisorLoaded(messages: event.messages));
  }

  Future<void> _onSendMessageRequested(SendMessageRequested event, Emitter<AiAdvisorState> emit) async {
    if (state is AiAdvisorLoaded) {
      final currentState = state as AiAdvisorLoaded;
      emit(AiAdvisorLoaded(
        messages: currentState.messages,
        isTyping: true,
      ));
    }

    try {
      await _aiAdvisorService.sendMessage(event.text);
      // Real-time stream will update the messages
    } catch (e) {
      if (state is AiAdvisorLoaded) {
        final currentState = state as AiAdvisorLoaded;
        emit(AiAdvisorLoaded(
          messages: currentState.messages,
          isTyping: false,
          error: e.toString(),
        ));
      }
    }
  }

  Future<void> _onClearChatRequested(ClearChatRequested event, Emitter<AiAdvisorState> emit) async {
    try {
      await _aiAdvisorService.clearHistory();
    } catch (e) {
      emit(AiAdvisorError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
