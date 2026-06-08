import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color accentColor = Color(0xFF3498DB);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFE0E5EC);
  static const Color surfaceLight = Color(0xFFE0E5EC);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF1E1E24);
  static const Color surfaceDark = Color(0xFF1E1E24);

  // Shadows
  static List<BoxShadow> get neumorphicShadowLight => [
        BoxShadow(
          color: Colors.white.withOpacity(0.5),
          offset: const Offset(-8, -8),
          blurRadius: 16,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(8, 8),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> get neumorphicShadowDark => [
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          offset: const Offset(-8, -8),
          blurRadius: 16,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(8, 8),
          blurRadius: 16,
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: primaryColor,
        surface: surfaceLight,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.poppins(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        elevation: 0,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.black38,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: surfaceDark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
      ),
    );
  }
}
