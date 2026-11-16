import 'package:flutter/material.dart';

class AppColors {
  static const Color navyPrimary = Color(0xFF0F2537);
  static const Color navyDark = Color(0xFF0A1926);
  static const Color yellowAccent = Color(0xFFFACC15);
  static const Color yellowSoft = Color(0xFFFEF9C3);
  static const Color yellowText = Color(0xFF854D0E);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF4F6F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F2537);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color badgeBlueBg = Color(0xFFEFF6FF);
  static const Color badgeBlueText = Color(0xFF1D4ED8);
  static const Color badgeGreenBg = Color(0xFFECFDF5);
  static const Color badgeGreenText = Color(0xFF047857);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navyPrimary,
        primary: AppColors.navyPrimary,
        secondary: AppColors.yellowAccent,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navyPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      fontFamily: 'Sans-Serif',
    );
  }
}