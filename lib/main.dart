// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:products/providers/theme_notifier.dart';
import 'package:products/screens/splash_screen.dart';
import 'package:products/services/storage_services.dart';
import 'package:products/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storageService = StorageService();
  final themeMode = await storageService.loadTheme();

  runApp(ProductManagementApp(initialThemeMode: themeMode));
}

class ProductManagementApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const ProductManagementApp({super.key, required this.initialThemeMode});

  @override
  State<ProductManagementApp> createState() => _ProductManagementAppState();
}

class _ProductManagementAppState extends State<ProductManagementApp> {
  late ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier(widget.initialThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Stock Up',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeNotifier.themeMode,
          home: SplashScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}
