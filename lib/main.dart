import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/screens/home_screen.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';
import 'package:table_tennis_scoreboard/screens/match_scorecard_screen.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';
import 'package:table_tennis_scoreboard/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/controller',
          builder: (BuildContext context, GoRouterState state) {
            final MatchController controller = state.extra as MatchController;
            return ControllerScreen(controller: controller);
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/scoreboard',
              builder: (BuildContext context, GoRouterState state) {
                final MatchController controller =
                    state.extra as MatchController;
                return ScoreboardDisplayScreen(controller);
              },
            ),
            GoRoute(
              path: '/match-card',
              builder: (BuildContext context, GoRouterState state) {
                final ctrl = state.extra as MatchController;
                return MatchScorecardScreen(ctrl: ctrl);
              },
            ),
            GoRoute(
              path: '/team-setup',
              builder: (BuildContext context, GoRouterState state) {
                return const TeamSetupScreen();
              },
            ),
            GoRoute(
              path: '/join-match',
              builder: (BuildContext context, GoRouterState state) {
                return const JoinMatchScreen();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

// void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Table Tennis Scoreboard',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: _router,
    );
  }
}
