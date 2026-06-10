import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  static const _keyEmail = 'user_email';
  static const _keyPin = 'user_pin';
  static const _keyBiometricEnabled = 'biometric_enabled';

  Future<void> saveCredentials(String email, String pin) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPin, value: pin);
  }

  Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final pin = await _storage.read(key: _keyPin);
    return {'email': email, 'pin': pin};
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
