import 'package:flutter/material.dart';

/// Traditional Indian art style theme for Ashta Chamma.
///
/// Uses warm earth tones inspired by traditional Indian art:
/// terracotta, ochre, deep red, gold, and cream.
class AshtaChammaTheme {
  AshtaChammaTheme._();

  // Primary colors
  static const Color terracotta = Color(0xFFC75B3B);
  static const Color ochre = Color(0xFFD4A24C);
  static const Color deepRed = Color(0xFF8B1A1A);
  static const Color gold = Color(0xFFDAA520);
  static const Color cream = Color(0xFFFFF8DC);

  // Player colors
  static const Color player1Color = Color(0xFFB22222); // Crimson/dark red
  static const Color player2Color = Color(0xFF1B3A6B); // Navy/dark blue

  // Board colors
  static const Color boardBackground = Color(0xFFFFF8DC); // Cream/tan
  static const Color boardLines = Color(0xFF3E2723); // Dark brown
  static const Color safeSquareColor = Color(0xFFDAA520); // Gold
  static const Color outerRingColor = Color(0xFFFAEBD7); // Antique white
  static const Color innerRingColor = Color(0xFFF5DEB3); // Wheat
  static const Color centerColor = Color(0xFFFFD700); // Bright gold

  // UI colors
  static const Color buttonColor = Color(0xFFC75B3B); // Terracotta
  static const Color buttonTextColor = Color(0xFFFFF8DC); // Cream
  static const Color textColor = Color(0xFF3E2723); // Dark brown
  static const Color subtitleColor = Color(0xFF5D4037); // Medium brown

  /// Creates the app ThemeData.
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: terracotta,
        primary: terracotta,
        secondary: ochre,
        surface: cream,
        onPrimary: cream,
        onSecondary: textColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepRed,
        foregroundColor: cream,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: buttonTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: deepRed,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: subtitleColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
