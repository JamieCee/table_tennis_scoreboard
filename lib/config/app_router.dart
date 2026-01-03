// lib/config/router/app_router.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';
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
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/splash_screen.dart';

class AppRouter {
  final AuthManager authManager;

  AppRouter({required this.authManager});

  late final GoRouter router = GoRouter(
    refreshListenable: authManager,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final bool loggedIn = authManager.isAuthenticated;
      final String location = state.matchedLocation;
      final bool isSubscribed = authManager.isSubscribed;

      final isSpectateRoute =
          location == '/controller/scoreboard' ||
          location == '/controller/match-card';
      final isPublicOnlyRoute = location == '/login' || location == '/';
      final isGoingToSubscribe = location == '/subscribe';

      final isSpectatorRoute =
          location == '/controller/scoreboard' ||
          location == '/controller/match-card';

      final isAuthRoute =
          (location.startsWith('/home') ||
              location.startsWith('/controller') ||
              location.startsWith('/team-setup')) &&
          !isSpectatorRoute;

      if (loggedIn && !isSubscribed && !isGoingToSubscribe) {
        return '/subscribe';
      }

      if (isSpectatorRoute) {
        return null;
      }

      if (kIsWeb) {
        if (location.startsWith('/controller')) {
          return '/join-match';
        }
        return null;
      }

      if (!loggedIn && isAuthRoute) {
        return '/login';
      }

      if (loggedIn && isSubscribed && isPublicOnlyRoute) {
        return '/home';
      }

      if (loggedIn && !isSubscribed && isGoingToSubscribe) {
        return null;
      }

      return null;
    },
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
          return BlocProvider(
            create: (context) => MatchControllerBloc(
              matchId: controller.matchId,
              home: controller.home,
              away: controller.away,
              isObserver: controller.isObserver,
              matchType: controller.matchType,
              setsToWin: controller.setsToWin,
              handicapDetails: controller.handicapDetails,
              matchStateManager: context.read<MatchStateManager>(),
            )..add(InitializeMatch()),
            child: const ControllerScreen(),
          );
        },
        routes: [
          GoRoute(
            path: 'scoreboard',
            builder: (context, state) {
              final bloc = state.extra as MatchControllerBloc;
              return BlocProvider.value(
                value: bloc,
                child: const ScoreboardDisplayScreen(),
              );
            },
          ),
          GoRoute(
            path: 'match-card',
            builder: (context, state) {
              final bloc = state.extra as MatchControllerBloc;
              return BlocProvider.value(
                value: bloc,
                child: const MatchScorecardScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
}
