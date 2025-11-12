import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE60012); // One Piece red
  static const Color secondaryColor = Color(0xFFFFD700); // Gold
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: primaryColor,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: primaryColor,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}