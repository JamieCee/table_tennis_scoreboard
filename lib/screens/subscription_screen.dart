import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';

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
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 125,
              child: DrawerHeader(
                decoration: BoxDecoration(color: AppColors.purpleAccent),
                padding: EdgeInsets.only(left: 20),
                child: Text('TT Scoreboard'),
              ),
            ),
            FutureBuilder<bool>(
              future: _secureStorage.isSubscribed(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);

                  _authController.logout();

                  if (!mounted) return;
                  context.go('/');
                },
              ),
          ],
        ),
      ),
    );
  }
}
