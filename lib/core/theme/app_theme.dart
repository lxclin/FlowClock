import 'package:flutter/material.dart';

class AppTheme {
  // Lo-Fi warm palette — low saturation, vintage feel
  static const Color workColor = Color(0xFFD4956A);     // warm terracotta
  static const Color breakColor = Color(0xFF8BA888);    // muted sage green
  static const Color bgCream = Color(0xFFFDF8F0);       // off-white cream
  static const Color bgWarm = Color(0xFFF5EDE0);        // warm beige
  static const Color surfaceColor = Color(0xFFFFF8F0);  // card surface
  static const Color textPrimary = Color(0xFF3D3929);   // dark brown
  static const Color textSecondary = Color(0xFF8B8578); // muted taupe
  static const Color trackColor = Color(0xFFE8E0D3);    // light beige track
  static const Color accentWarm = Color(0xFFC4845C);    // deeper terracotta
  static const Color accentCool = Color(0xFF7A9E7E);    // deeper sage
  static const Color dividerColor = Color(0xFFE5DDCF);

  // 8 Lo-Fi task card gradients
  static const List<List<Color>> taskGradients = [
    [Color(0xFFFDF8F0), Color(0xFFF5E1D0)], // warm orange
    [Color(0xFFFDF8F0), Color(0xFFDDE8D8)], // sage green
    [Color(0xFFFDF8F0), Color(0xFFD8E2EB)], // misty blue
    [Color(0xFFFDF8F0), Color(0xFFE4DBEE)], // soft purple
    [Color(0xFFFDF8F0), Color(0xFFF2D8D8)], // blush pink
    [Color(0xFFFDF8F0), Color(0xFFF2EED8)], // butter yellow
    [Color(0xFFFDF8F0), Color(0xFFD8EDE4)], // mint
    [Color(0xFFFDF8F0), Color(0xFFE5DFD3)], // warm grey
  ];

  static const List<Color> taskAccentColors = [
    Color(0xFFD4956A),
    Color(0xFF8BA888),
    Color(0xFF7B9CB5),
    Color(0xFF9B8DB5),
    Color(0xFFC48B8B),
    Color(0xFFC4A962),
    Color(0xFF7BA896),
    Color(0xFFA89882),
  ];

  // Backward-compatible aliases
  static const Color workBackground = bgWarm;
  static const Color breakBackground = Color(0xFFEEF4EB);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: workColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgCream,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: bgCream,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: surfaceColor,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: workColor,
          unselectedItemColor: textSecondary,
          elevation: 0,
          backgroundColor: surfaceColor,
        ),
        dividerTheme: const DividerThemeData(
          color: dividerColor,
          thickness: 1,
        ),
      );
}
