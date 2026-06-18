import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  /// Hashes a PIN using SHA-256 and returns the hex string representation.
  /// This mirrors the logic used in the web application for cross-platform compatibility.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
