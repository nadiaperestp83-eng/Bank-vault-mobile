import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, codeSent, authenticated, error }

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyOtp(String email, String token) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedToken = token.trim();

    try {
      // 1. Try magiclink (standard for existing users)
      return await _supabase.auth.verifyOTP(
        email: trimmedEmail,
        token: trimmedToken,
        type: OtpType.magiclink,
      );
    } catch (e) {
      // 2. Fallback to signup (standard for new users)
      try {
        return await _supabase.auth.verifyOTP(
          email: trimmedEmail,
          token: trimmedToken,
          type: OtpType.signup,
        );
      } catch (e2) {
        // 3. Fallback to invite (some organizations use this)
        try {
          return await _supabase.auth.verifyOTP(
            email: trimmedEmail,
            token: trimmedToken,
            type: OtpType.invite,
          );
        } catch (e3) {
          // If all failed, throw a meaningful error.
          // We prefer the original error if it was "expired", but usually e2/e3 are "invalid".
          if (e.toString().contains('expired') || e2.toString().contains('expired')) {
            throw 'The code has expired. Please request a new one.';
          }
          throw 'Invalid verification code. Please check and try again.';
        }
      }
    }
  }

  Future<bool> checkProfileExists(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    return response != null;
  }

  Future<bool> hasTransactionPin(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('pin_hash')
        .eq('id', userId)
        .maybeSingle();
    return response?['pin_hash'] != null;
  }
  
  User? get currentUser => _supabase.auth.currentUser;
  
  Session? get currentSession => _supabase.auth.currentSession;

  Future<void> logActivity(String actionType, {String? userId}) async {
    final uid = userId ?? _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _supabase.from('activity_logs').insert({
        'user_id': uid,
        'action_type': actionType,
        'device_info': 'Mobile App',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail logging to avoid disrupting the main flow
      print('Failed to log activity: $e');
    }
  }
}
