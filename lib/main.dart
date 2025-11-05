import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_tennis_scoreboard/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

// void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Table Tennis Scoreboard',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
