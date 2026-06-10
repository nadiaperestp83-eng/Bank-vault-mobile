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

    // 1. Insert user message
    await _supabase.from('ai_chat_messages').insert({
      'user_id': userId,
      'sender': 'user',
      'text': text,
    });

    // 2. Invoke Edge Function
    try {
      final response = await _supabase.functions.invoke(
        'gemini-chat',
        body: {'message': text},
      );

      final String aiReply = response.data['reply'] ?? "I'm sorry, I couldn't process that.";

      // 3. Insert AI response (The Edge function might already do this, 
      // but if not, we do it here for permanence as per requirements)
      // Check if already inserted by function to avoid duplicates
      final history = await getChatHistory();
      if (history.isEmpty || history.last.text != aiReply) {
        await _supabase.from('ai_chat_messages').insert({
          'user_id': userId,
          'sender': 'advisor',
          'text': aiReply,
        });
      }
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
