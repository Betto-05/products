// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF276749);
  static const Color secondaryColor = Color(0xFF38A169);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF7FAFC),
    fontFamily: 'Gilroy',
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF2D3748),
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Gilroy',
      bodyColor: const Color(0xFF2D3748),
      displayColor: const Color(0xFF2D3748),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF2D3748)),
      titleTextStyle: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D3748),
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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade400,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: false,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF1A202C),
    fontFamily: 'Gilroy',
    cardColor: const Color(0xFF2D3748),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF2D3748),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFEDF2F7),
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Gilroy',
      bodyColor: const Color(0xFFEDF2F7),
      displayColor: const Color(0xFFEDF2F7),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFEDF2F7)),
      titleTextStyle: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFFEDF2F7),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF2D3748),
      selectedItemColor: secondaryColor,
      unselectedItemColor: Colors.grey.shade500,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: false,
    ),
    inputDecorationTheme: const InputDecorationTheme(filled: true),
  );
}
