import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:products/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<Offset> _textSlide;
  late Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoRotate = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Background animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _bgShift = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Navigate to main screen
    Timer(const Duration(milliseconds: 3000), _navigateToHome);
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const CategoryScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.6 + _bgShift.value * 0.3, -1),
                end: Alignment(0.6 - _bgShift.value * 0.3, 1),
                colors: [primary.withOpacity(0.9), secondary.withOpacity(0.8)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _logoRotate.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Image.asset("assets/logo.png"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          'Product Manager',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLoadingDots(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            double opacity =
                (sin((_bgController.value * 2 * pi) + (i * 0.8)) + 1) / 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity,
                child: const Text(
                  '●',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
