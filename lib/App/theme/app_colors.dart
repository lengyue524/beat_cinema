import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brandPurple = Color(0xFF9B59FF);
  static const Color seedColor = Color.fromARGB(255, 123, 0, 255);

  // Surface 5-layer depth system (dark theme)
  static const Color surface0 = Color(0xFF141422);
  static const Color surface1 = Color(0xFF1A1A2E);
  static const Color surface2 = Color(0xFF1E1E35);
  static const Color surface3 = Color(0xFF24243B);
  static const Color surface4 = Color(0xFF2A2A42);

  // Semantic state colors
  static const Color success = Color(0xFF9B59FF);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFCF6679);
  static const Color info = Color(0xFF80CBC4);

  // Foreground text colors (on dark surfaces, WCAG AA compliant)
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF616161);

  // Divider
  static const Color divider = Color(0xFF2A2A42);
}

class BeatSaberColors {
  BeatSaberColors._();

  static const Color easy = Color(0xFF3CB371);
  static const Color normal = Color(0xFF59B0F4);
  static const Color hard = Color(0xFFFF6347);
  static const Color expert = Color(0xFFBF2A52);
  static const Color expertPlus = Color(0xFF8F48DB);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
