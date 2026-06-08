import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Mode (The Deep Vault) ---
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0x661E293B); // rgba(30, 41, 59, 0.4)
  static const Color darkPrimary = Color(0xFF10B981); // Emerald
  static const Color darkHeading = Color(0xFFFFFFFF);
  static const Color darkBody = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkWarning = Color(0xFFF59E0B);

  // --- Light Mode (The Pristine Ledger) ---
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xB3FFFFFF); // rgba(255, 255, 255, 0.7)
  static const Color lightPrimary = Color(0xFF059669); // Forest Green
  static const Color lightHeading = Color(0xFF0F172A);
  static const Color lightBody = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightWarning = Color(0xFFD97706);

  // Aliases for compatibility
  static const Color backgroundLight = lightBackground;
  static const Color backgroundDark = darkBackground;
  static const Color charcoal = darkBackground;
  static const Color primary = darkPrimary;
  static const Color primaryDark = Color(0xFF059669); // Forest Green from light mode or actual dark variant
  static const Color primaryLight = Color(0xFF34D399);
  
  static const Color surfaceLight = lightSurface;
  static const Color surfaceDark = darkSurface;
  
  static const Color textPrimaryLight = lightHeading;
  static const Color textSecondaryLight = lightBody;
  static const Color textPrimaryDark = darkHeading;
  static const Color textSecondaryDark = darkBody;

  static const Color accent = Color(0xFF6366F1); // Indigo 500
  static const Color accentDark = Color(0xFF4F46E5); // Indigo 600

  static const Color success = darkPrimary;
  static const Color error = darkError;
  static const Color warning = darkWarning;
}
