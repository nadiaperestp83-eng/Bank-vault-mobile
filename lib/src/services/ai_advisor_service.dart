import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_advisor_model.dart';

class AiAdvisorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<AiChatMessage>> watchMessages() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('ai_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => AiChatMessage.fromJson(json)).toList());
  }

  Future<List<AiChatMessage>> getChatHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('ai_chat_messages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => AiChatMessage.fromJson(json)).toList();
  }

  Future<void> sendMessage(String text) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Fetch current history for grounding
    final history = await getChatHistory();

    // Convert history to a lightweight format for the Edge Function
    final messages = history.map((m) => {
      'role': m.sender == 'user' ? 'user' : 'model',
      'content': m.text,
    }).toList();

    // 2. Insert user message locally
    await _supabase.from('ai_chat_messages').insert({
      'user_id': userId,
      'sender': 'user',
      'text': text,
    });

    // 3. Invoke Edge Function with Grounding Context
    try {
      final response = await _supabase.functions.invoke(
        'gemini-chat',
        body: {
          'userInput': text,
          'messages': messages,
        },
      );

      final String aiReply = response.data['text'] ?? response.data['reply'] ?? "I'm sorry, I couldn't process that.";

      // 4. Insert AI response
      await _supabase.from('ai_chat_messages').insert({
        'user_id': userId,
        'sender': 'advisor',
        'text': aiReply,
      });
    } catch (e) {
       await _supabase.from('ai_chat_messages').insert({
        'user_id': userId,
        'sender': 'advisor',
        'text': "I'm having trouble connecting to my brain right now. Please try again later.",
      });
    }
  }
  Future<void> clearHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('ai_chat_messages').delete().eq('user_id', userId);
  }
}
