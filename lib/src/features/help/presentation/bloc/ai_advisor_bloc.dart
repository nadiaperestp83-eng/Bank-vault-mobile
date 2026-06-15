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
    if (state is AiAdvisorLoaded && _messagesSubscription != null) return;

    emit(AiAdvisorLoading());
    await _messagesSubscription?.cancel();
    _messagesSubscription = _aiAdvisorService.watchMessages().listen(
      (messages) => add(ChatUpdated(messages)),
      onError: (error) => emit(AiAdvisorError(error.toString())),
    );
  }

  void _onChatUpdated(ChatUpdated event, Emitter<AiAdvisorState> emit) {
    bool wasTyping = false;
    if (state is AiAdvisorLoaded) {
      wasTyping = (state as AiAdvisorLoaded).isTyping;
    }

    // Stop typing indicator if the last message is from the advisor
    bool stillTyping = wasTyping;
    if (event.messages.isNotEmpty && event.messages.last.sender == 'advisor') {
      stillTyping = false;
    }

    emit(AiAdvisorLoaded(
      messages: event.messages,
      isTyping: stillTyping,
    ));
  }

  Future<void> _onSendMessageRequested(SendMessageRequested event, Emitter<AiAdvisorState> emit) async {
    if (state is AiAdvisorLoaded) {
      final currentState = state as AiAdvisorLoaded;
      emit(currentState.copyWith(isTyping: true));
    }

    try {
      await _aiAdvisorService.sendMessage(event.text);
      
      // Manual refresh as a fallback for mobile stream issues
      final messages = await _aiAdvisorService.getChatHistory();
      add(ChatUpdated(messages));
    } catch (e) {
      if (state is AiAdvisorLoaded) {
        final currentState = state as AiAdvisorLoaded;
        emit(currentState.copyWith(
          isTyping: false,
          error: e.toString(),
        ));
      }
    } finally {
      // Safety fallback: if after 10 seconds we are still typing, reset it
      // This handles cases where the stream might be slow or fail on mobile
      Future.delayed(const Duration(seconds: 10), () {
        if (isClosed) return;
        if (state is AiAdvisorLoaded && (state as AiAdvisorLoaded).isTyping) {
          add(ChatUpdated((state as AiAdvisorLoaded).messages)); // This will trigger _onChatUpdated and reset isTyping
        }
      });
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
