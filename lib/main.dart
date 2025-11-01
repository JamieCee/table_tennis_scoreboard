import 'package:flutter/material.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Table Tennis Scoreboard',
      theme: ThemeData.dark(useMaterial3: true),
      home: const TeamSetupScreen(),
    );
  }
}
