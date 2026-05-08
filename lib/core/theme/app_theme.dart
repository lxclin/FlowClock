import 'package:flutter/material.dart';

class AppTheme {
  static const Color workColor = Color(0xFFFF6B6B);
  static const Color breakColor = Color(0xFF51CF66);
  static const Color workBackground = Color(0xFFFFF5F5);
  static const Color breakBackground = Color(0xFFF0FFF3);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF868E96);
  static const Color trackColor = Color(0xFFE9ECEF);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: workColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: surfaceColor,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: workColor,
          unselectedItemColor: textSecondary,
          elevation: 0,
        ),
      );
}
