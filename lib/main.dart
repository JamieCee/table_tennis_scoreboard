// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/services/api/chopper_client.dart';
import 'package:table_tennis_scoreboard/services/auth_manager.dart';

import 'config/app_router.dart';
import 'firebase_options.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.create();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // Provide the AuthManager to the entire widget tree.
    ChangeNotifierProvider(
      create: (context) => AuthManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create an instance of the router, passing it the AuthManager from the provider.
    final appRouter = AppRouter(authManager: context.watch<AuthManager>());

    return OrientationWrapper(
      child: MaterialApp.router(
        title: 'Table Tennis Scoreboard',
        theme: ThemeData.dark(useMaterial3: true),
        // Use the router instance from your AppRouter class.
        routerConfig: appRouter.router,
      ),
    );
  }
}

/// Widget that locks orientation based on device width (remains the same)
class OrientationWrapper extends StatelessWidget {
  final Widget child;
  const OrientationWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        if (isTablet) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
        return child;
      },
    );
  }
}
