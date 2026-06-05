import 'package:flutter/material.dart';

class AppColors {
  // Primary: Emerald/Teal (Success/Growth)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400

  // Accents: Indigo
  static const Color accent = Color(0xFF6366F1); // Indigo 500
  static const Color accentDark = Color(0xFF4F46E5); // Indigo 600

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  
  // Surface/Glassmorphism
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1F2937);
  static Color glassWhite = Colors.white.withOpacity(0.1);
  static Color glassBlack = Colors.black.withOpacity(0.1);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
}
