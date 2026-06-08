import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, codeSent, authenticated, error }

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyOtp(String email, String token) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.magiclink, // Using magiclink for OTP verification
    );
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
        .select('has_pin')
        .eq('id', userId)
        .maybeSingle();
    return response?['has_pin'] ?? false;
  }
  
  User? get currentUser => _supabase.auth.currentUser;
  
  Session? get currentSession => _supabase.auth.currentSession;
}
