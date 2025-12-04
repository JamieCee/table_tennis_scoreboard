import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    /// ---------------- SPLASH ----------------
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    /// ---------------- HOME ----------------
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    /// ---------------- TEAM SETUP ----------------
    GoRoute(
      path: '/team-setup',
      builder: (context, state) => const TeamSetupScreen(),
    ),

    /// ---------------- JOIN MATCH ----------------
    GoRoute(
      path: '/join-match',
      builder: (context, state) => const JoinMatchScreen(),
    ),

    /// ---------------- CONTROLLER ----------------
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
