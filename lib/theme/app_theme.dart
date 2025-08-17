// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define your color constants
  static const Color primaryColor = Color(0xFF276749); // Dark green
  static const Color secondaryColor = Color(0xFF38A169); // Vibrant green
  static const Color backgroundColor = Color(0xFFF7FAFC); // Soft off-white
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2D3748); // Dark grey for text

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.nunitoSans().fontFamily,
      cardColor: cardColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoSansTextTheme(
        Theme.of(context).textTheme,
      ).apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
