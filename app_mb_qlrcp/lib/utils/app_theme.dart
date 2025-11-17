import 'package:flutter/material.dart';

class AppTheme {
  // Màu cam chủ đạo
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color darkOrange = Color(0xFFE85D25);
  static const Color lightOrange = Color(0xFFFF8C5F);
  static const Color paleOrange = Color(0xFFFFF3EF);

  // Màu bổ sung
  static const Color darkGray = Color(0xFF2C2C2C);
  static const Color mediumGray = Color(0xFF6C6C6C);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);

  // Màu trạng thái
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: white,
      colorScheme: ColorScheme.light(
        primary: primaryOrange,
        secondary: darkOrange,
        surface: white,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1),
        ),
        prefixIconColor: primaryOrange,
        labelStyle: const TextStyle(color: mediumGray),
        hintStyle: TextStyle(color: mediumGray.withOpacity(0.6)),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: white,
      ),
    );
  }

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: darkGray,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: darkGray,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: darkGray,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, color: darkGray);

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: mediumGray,
  );

  static const TextStyle bodySmall = TextStyle(fontSize: 12, color: mediumGray);
}
