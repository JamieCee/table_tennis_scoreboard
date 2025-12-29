import 'dart:async';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      final token = await _secureStorage.getAccessToken();
      if (!mounted) return;

      if (token != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Expanded(
            child: Center(
              child: LottieBuilder.asset(
                "assets/images/table_tennis_splash.json",
              ),
            ),
          ),
        ],
      ),
      splashIconSize: 400,
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.rightToLeft,

      /// ⚠️ We disable internal routing by using a dummy screen
      nextScreen: const SizedBox.shrink(),

      duration: 1000,
      backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.5),
    );
  }
}
