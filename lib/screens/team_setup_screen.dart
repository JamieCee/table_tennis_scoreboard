import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _homeNameController = TextEditingController(text: 'Home Team');
  final _awayNameController = TextEditingController(text: 'Away Team');

  final _homePlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'H${i + 1}'),
  );
  final _awayPlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'A${i + 1}'),
  );

  void _startMatch() {
    final home = Team(
      name: _homeNameController.text,
      players: _homePlayers.map((c) => Player(c.text)).toList(),
    );
    final away = Team(
      name: _awayNameController.text,
      players: _awayPlayers.map((c) => Player(c.text)).toList(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MatchController(home: home, away: away),
          child: const ControllerScreen(showDialogOnLoad: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _teamInput("Home Team", _homeNameController, _homePlayers),
            const SizedBox(height: 24),
            _teamInput("Away Team", _awayNameController, _awayPlayers),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startMatch,
              label: const Text("Start Match"),
              icon: const Icon(Icons.play_arrow),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamInput(
    String label,
    TextEditingController teamController,
    List<TextEditingController> playerControllers,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: teamController,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++)
              TextField(
                controller: playerControllers[i],
                decoration: InputDecoration(labelText: 'Player ${i + 1}'),
              ),
          ],
        ),
      ),
    );
  }
}
