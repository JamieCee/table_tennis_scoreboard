import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

import '../controllers/auth_controller.dart';
import '../theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _authController = AuthController();
  final _secureStorage = SecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3E4249),
      appBar: AppBar(
        title: Text(
          'TT Scoreboard',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBackground,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'You currently do not have an active subscription. To make use of this app and it\'s features, please subscribe.',
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
    );
  }
}
