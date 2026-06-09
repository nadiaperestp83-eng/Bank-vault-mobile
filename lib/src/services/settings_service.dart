import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vault_os/src/models/profile_model.dart';
import 'package:vault_os/src/models/preferences_model.dart';
import 'package:vault_os/src/models/merchant_model.dart';
import 'package:vault_os/src/models/device_model.dart';
import 'package:vault_os/src/services/supabase_service.dart';

class SettingsService {
  final SupabaseClient _supabase = SupabaseService.client;

  // --- Real-time Sync ---

  Stream<Profile?> watchProfile(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
  }

  Stream<UserPreferences?> watchPreferences(String userId) {
    return _supabase
        .from('user_preferences')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.isEmpty ? null : UserPreferences.fromJson(data.first));
  }

  Stream<List<Merchant>> watchMerchants(String userId) {
    return _supabase
        .from('merchants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => Merchant.fromJson(json)).toList());
  }

  Stream<List<UserDevice>> watchDevices(String userId) {
    return _supabase
        .from('user_devices')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => UserDevice.fromJson(json)).toList());
  }

  // --- Profile Management ---

  Future<void> updateProfile(Profile profile) async {
    Map<String, dynamic> data = profile.toJson();
    
    // If kyc_tag is empty, generate a unique one
    if (profile.kycTag.isEmpty) {
      final generatedTag = await generateUniqueKycTag(profile.firstName, profile.lastName);
      data['kyc_tag'] = generatedTag;
    }

    await _supabase.from('profiles').update(data).eq('id', profile.id);
  }

  Future<String> generateUniqueKycTag(String firstName, String lastName) async {
    String baseTag = '@${firstName.toLowerCase()}${lastName.toLowerCase()}'.replaceAll(RegExp(r'[^a-z0-9@]'), '');
    if (baseTag == '@') baseTag = '@user';
    
    String currentTag = baseTag;
    int suffix = 1;

    while (true) {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('kyc_tag', currentTag)
          .maybeSingle();

      if (response == null) return currentTag;
      currentTag = '$baseTag$suffix';
      suffix++;
    }
  }

  Future<String> uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$userId/$timestamp.$fileExt';

    await _supabase.storage.from('avatars').upload(filePath, file);

    final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
    
    await _supabase.from('profiles').update({
      'profile_photo_url': publicUrl,
    }).eq('id', userId);

    return publicUrl;
  }

  // --- Security & Session ---

  Future<void> revokeDevice(String deviceId) async {
    await _supabase.from('user_devices').update({
      'is_active': false,
    }).eq('id', deviceId);
  }

  Future<void> requestPinResetOtp(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyPinResetOtp(String email, String token) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<void> updatePin(String userId, String newPin) async {
    final hashedPin = SupabaseService.hashPin(newPin);
    await _supabase.from('profiles').update({
      'pin_hash': hashedPin,
    }).eq('id', userId);
  }

  Future<bool> verifyCurrentPin(String userId, String pin) async {
    final hashedPin = SupabaseService.hashPin(pin);
    final response = await _supabase.rpc('verify_current_pin', params: {
      'p_user_id': userId,
      'p_pin_hash': hashedPin,
    });
    return response as bool;
  }

  // --- Merchant Mode ---

  Future<void> activateMerchantMode(String userId, String businessName, String businessType) async {
    await _supabase.from('merchants').upsert({
      'user_id': userId,
      'business_name': businessName,
      'business_type': businessType,
      'is_active': true,
    });
  }

  // --- Account Deletion ---

  Future<Map<String, dynamic>> checkAssetsForDeletion(String userId) async {
    final response = await _supabase.rpc('check_user_assets', params: {'p_user_id': userId});
    return Map<String, dynamic>.from(response);
  }

  Future<void> requestAccountDeletion(String userId, String email) async {
    await _supabase.functions.invoke('send-predelete-email', body: {
      'userId': userId,
      'email': email,
    });
  }

  // --- Preferences ---

  Future<void> updatePreferences(UserPreferences preferences) async {
    await _supabase.from('user_preferences').update(preferences.toJson()).eq('user_id', preferences.userId);
  }

  Future<void> updateTheme(String userId, String theme) async {
    await _supabase.from('user_preferences').update({'theme': theme}).eq('user_id', userId);
  }

  Future<void> updateLanguage(String userId, String language) async {
    await _supabase.from('user_preferences').update({'language': language}).eq('user_id', userId);
  }

  Future<void> updateCurrency(String userId, String currency) async {
    await _supabase.from('profiles').update({'primary_currency': currency}).eq('id', userId);
  }
}
