// lib/widgets/app_drawer.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/controllers/auth_controller.dart';
import 'package:table_tennis_scoreboard/services/auth_manager.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // These can be defined here now, as this is a self-contained widget.
    final authManager = Provider.of<AuthManager>(context);
    final authController = AuthController();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- DRAWER HEADER ---
          Container(
            height: 125,
            padding: const EdgeInsets.fromLTRB(
              20,
              40,
              20,
              16,
            ), // A more balanced padding
            decoration: BoxDecoration(color: AppColors.purpleAccent),
            child: const Align(
              alignment: Alignment.centerLeft, // Aligns the text to the left
              child: Text(
                'Digital Scoreboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (!authManager.isAuthenticated && !kIsWeb)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                context.pushReplacement('/login');
              },
            ),
          if (authManager.isAuthenticated) ...[
            // --- HOME TILE ---
            if (authManager.isSubscribed) ...[
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
              ),
            ],

            //TODO: Will need to add a check later to prevent a controller from joining a match while they are active
            ListTile(
              title: const Text('Join Match'),
              leading: const Icon(Icons.sports_tennis),
              onTap: () {
                Navigator.pop(context);
                context.go('/join-match');
              },
            ),

            // --- LOGOUT TILE (for mobile) ---
            // The check for kIsWeb is still valid here because web users can't "log in" in your setup.
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  authController.logout(context);
                },
              ),
          ],
        ],
      ),
    );
  }
}
