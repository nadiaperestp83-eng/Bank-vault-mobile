import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['VITE_SUPABASE_URL']!,
      publishableKey: dotenv.env['VITE_SUPABASE_ANON_KEY']!,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> initializeUserDatabase({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String pin,
    String? username,
  }) async {
    // 1. Generate KYC Tag (e.g., @username or @firstname)
    final tagBase = username ?? firstName;
    final kycTag = '@${tagBase.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

    // 2. Create Profile
    await client.from('profiles').upsert({
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phone,
      'pin_hash': hashPin(pin),
      'kyc_status': 'unverified',
      'kyc_tag': kycTag,
      'primary_currency': 'KES',
    });

    // 3. Initialize Wallet
    await client.from('wallets').insert({
      'user_id': userId,
      'balance': 0.0,
      'currency': 'KES',
    });

    // 4. Set Preferences
    await client.from('user_preferences').upsert({
      'user_id': userId,
      'theme': 'system',
    });
  }
}
