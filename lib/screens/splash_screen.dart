import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quraan_tafseer/constants/colors.dart';
import 'package:quraan_tafseer/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  static const _splashDuration = Duration(seconds: 5);

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _navigate);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final scale = 1.0 + (_glowAnimation.value * 0.2);
            final opacity = 0.4 + (_glowAnimation.value * 0.6);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.7),
                            blurRadius: 40.0,
                            spreadRadius: 15.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/splash2.png',
                  width: 120,
                  height: 120,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
