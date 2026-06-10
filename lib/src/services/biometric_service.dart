import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to proceed',
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      // Using basic parameters for maximum compatibility across local_auth versions
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException {
      return false;
    }
  }
}
