import 'package:flutter/material.dart';

/// App theme configuration - Dark Minimal theme per SRD/Handoff Phase 2
class AppTheme {
  // Dominant colors (60%)
  static const Color canvasColor = Color(0xFFEDEBF1);
  static const Color surfaceColor = Color(0xFFFAFAFB);
  
  // Secondary colors (30%)
  static const Color darkColor = Color(0xFF1C1C1E);
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkSecondary = Colors.white54;
  
  // Accent colors (10%)
  static const Color accentFill = Color(0xFFE8E6FA);
  static const Color accentText = Color(0xFF3C3489);

  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color dividerColor = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentText,
        brightness: Brightness.light,
        primary: darkColor,
        secondary: accentText,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: canvasColor,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: canvasColor,
        foregroundColor: darkColor,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textPrimary),
      ),
    );
  }

  // Locked Dark Theme Colors
  static const Color darkPageBg = Color(0xFF0F0F11);
  static const Color darkCardBg = Color(0xFF1C1C1E);
  static const Color darkEmphasizedBg = Color(0xFFFFFFFF);
  static const Color darkEmphasizedText = Color(0xFF1C1C1E);
  static const Color darkAccent = Color(0xFFB8B0FF);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9A9A9E);

  // Status Badges
  static const Color statusAvailableBg = Color(0xFF1A2E14);
  static const Color statusAvailableText = Color(0xFF7ED957);
  static const Color statusInClassBg = Color(0xFF3D1A1A);
  static const Color statusInClassText = Color(0xFFFF6B6B);
  static const Color statusUnknownBg = Color(0xFF2A2A2D);
  static const Color statusUnknownText = Color(0xFF9A9A9E);

  // Strict dark theme per Phase 2B Part 2
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccent,
        brightness: Brightness.dark,
        primary: darkEmphasizedBg,
        secondary: darkAccent,
        surface: darkCardBg,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkPageBg,
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkPageBg,
        foregroundColor: darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: darkTextSecondary),
      ),
    );
  }
}