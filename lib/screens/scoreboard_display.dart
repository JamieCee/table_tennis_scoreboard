import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';

import '../controllers/match_controller.dart';

class ScoreboardDisplayScreen extends StatelessWidget {
  const ScoreboardDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scoreboard Display'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_remote),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: Provider.of<MatchController>(context, listen: false),
                    child: const ControllerScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "🏓 TABLE TENNIS SCOREBOARD",
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),

              // Team Names + Match Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _teamBlock(
                    ctrl.home.name,
                    ctrl.matchGamesWonHome,
                    Colors.blueAccent,
                  ),
                  _teamBlock(
                    ctrl.away.name,
                    ctrl.matchGamesWonAway,
                    Colors.redAccent,
                  ),
                ],
              ),

              // Game info
              Column(
                children: [
                  Text(
                    "Game ${ctrl.currentGame.order} of ${ctrl.games.length} | "
                    "Set ${ctrl.currentGame.sets.length}",
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  Text(
                    "${ctrl.currentGame.homePlayers.map((p) => p.name).join(' & ')} "
                    "vs "
                    "${ctrl.currentGame.awayPlayers.map((p) => p.name).join(' & ')}",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ],
              ),

              // Big Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "${ctrl.currentSet.home}",
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Text(
                    "—",
                    style: TextStyle(fontSize: 100, color: Colors.white54),
                  ),
                  Text(
                    "${ctrl.currentSet.away}",
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),

              // Sets summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "${ctrl.currentGame.setsWonHome} Sets",
                    style: TextStyle(fontSize: 36, color: Colors.blueAccent),
                  ),
                  Text(
                    "${ctrl.currentGame.setsWonAway} Sets",
                    style: TextStyle(fontSize: 36, color: Colors.redAccent),
                  ),
                ],
              ),

              // Server indicator
              if (ctrl.currentServer != null && ctrl.currentReceiver != null)
                Text(
                  "🟢 Serving: ${ctrl.currentServer!.name} → ${ctrl.currentReceiver!.name}",
                  style: TextStyle(fontSize: 22, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamBlock(String name, int score, Color color) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text("$score", style: TextStyle(fontSize: 32, color: Colors.white)),
      ],
    );
  }
}
