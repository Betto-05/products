// lib/screens/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:products/providers/theme_notifier.dart';
import 'package:products/screens/home_screen.dart';
import 'package:products/screens/login_screen.dart';
import 'package:products/services/auth_services.dart';

class AuthGate extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const AuthGate({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomePage(themeNotifier: themeNotifier);
        }
        return LoginScreen(themeNotifier: themeNotifier);
      },
    );
  }
}
