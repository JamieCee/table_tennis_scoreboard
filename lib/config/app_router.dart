// lib/config/router/app_router.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/screens/home_screen.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';
import 'package:table_tennis_scoreboard/screens/login_screen.dart';
import 'package:table_tennis_scoreboard/screens/match_scorecard_screen.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/subscription_screen.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';
import 'package:table_tennis_scoreboard/services/auth_manager.dart';
import 'package:table_tennis_scoreboard/splash_screen.dart';

class AppRouter {
  final AuthManager authManager;

  AppRouter({required this.authManager});

  late final GoRouter router = GoRouter(
    // Listen to the AuthManager for changes in authentication state.
    refreshListenable: authManager,

    // Set the initial route. The redirect logic will handle where to go from there.
    initialLocation: '/',

    // --- ROUTE GUARD (REDIRECT) LOGIC ---
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authManager.isAuthenticated;
      final String location = state.matchedLocation;

      // Can spectate game
      final bool isSpectatorRoute =
          location == '/controller/scoreboard' ||
          location == '/controller/match-card';

      // Define which routes are protected and require authentication.
      final isAuthRoute =
          location.startsWith('/home') ||
          location.startsWith('/controller') ||
          location.startsWith('/team-setup') ||
          location.startsWith('/subscribe') && !isSpectatorRoute;

      // Define routes that a logged-in user should NOT be able to access.
      final isPublicOnlyRoute =
          location == '/login' || location == '/'; // Splash/Login

      // --- RULES ---

      if (isSpectatorRoute) {
        return null;
      }

      // 1. Web spectator logic:
      if (kIsWeb) {
        // On web, you can't be a controller. Redirect to join match page.
        if (location.startsWith('/controller')) {
          return '/join-match';
        }
        // Otherwise, allow access to view other pages like scoreboard.
        return null;
      }

      // 2. Unauthenticated user trying to access a protected route.
      if (!loggedIn && isAuthRoute) {
        return '/login'; // Redirect to the login screen.
      }

      // 3. Authenticated user trying to access a public-only route (like login).
      if (loggedIn && isPublicOnlyRoute) {
        return '/home'; // Redirect to the home screen.
      }

      // 4. No redirection needed, proceed to the intended route.
      return null;
    },

    // --- ROUTES CONFIGURATION ---
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/subscribe',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/team-setup',
        builder: (context, state) => const TeamSetupScreen(),
      ),
      GoRoute(
        path: '/join-match',
        builder: (context, state) => const JoinMatchScreen(),
      ),
      GoRoute(
        path: '/controller',
        builder: (context, state) {
          final controller = state.extra as MatchController;
          return ChangeNotifierProvider.value(
            value: controller,
            child: ControllerScreen(controller: controller),
          );
        },
        routes: [
          GoRoute(
            path: 'scoreboard',
            builder: (context, state) {
              final controller = state.extra as MatchController;
              return ChangeNotifierProvider.value(
                value: controller,
                child: ScoreboardDisplayScreen(controller),
              );
            },
          ),
          GoRoute(
            path: 'match-card',
            builder: (context, state) {
              final controller = state.extra as MatchController;
              return ChangeNotifierProvider.value(
                value: controller,
                child: MatchScorecardScreen(ctrl: controller),
              );
            },
          ),
        ],
      ),
    ],
  );
}
