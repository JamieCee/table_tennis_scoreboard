import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/widgets/doubles_server_picker.dart';

import '../controllers/match_controller.dart';

class ScoreboardDisplayScreen extends StatefulWidget {
  const ScoreboardDisplayScreen({super.key});

  @override
  State<ScoreboardDisplayScreen> createState() =>
      _ScoreboardDisplayScreenState();
}

class _ScoreboardDisplayScreenState extends State<ScoreboardDisplayScreen> {
  @override
  void initState() {
    super.initState();
    // We need to wait for the first frame to be built before showing a dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<MatchController>();
      ctrl.onDoublesPlayersNeeded = _showPicker;
      ctrl.onServerSelectionNeeded = _showPicker;

      // The controller calls _loadGame in its constructor. We need to check here
      // if a picker needs to be shown for the very first game.
      if (ctrl.currentServer == null) {
        _showPicker();
      }
    });
  }

  @override
  void dispose() {
    // Avoid trying to access context in dispose by using listen: false
    final ctrl = Provider.of<MatchController>(context, listen: false);
    ctrl.onDoublesPlayersNeeded = null;
    ctrl.onServerSelectionNeeded = null;
    super.dispose();
  }

  void _showPicker() {
    // Check if a dialog is already open to prevent showing multiple dialogs.
    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<MatchController>(),
          child: const DoublesServerPicker(),
        ),
      );
    }
  }

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
                    style: const TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  if (ctrl.currentGame.homePlayers.isNotEmpty ||
                      ctrl.currentGame.awayPlayers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "${ctrl.currentGame.homePlayers.map((p) => p.name).join(' & ')} "
                        "vs "
                        "${ctrl.currentGame.awayPlayers.map((p) => p.name).join(' & ')}",
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),

              // Big Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "${ctrl.currentSet.home}",
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Text(
                    "—",
                    style: TextStyle(fontSize: 100, color: Colors.white54),
                  ),
                  Text(
                    "${ctrl.currentSet.away}",
                    style: const TextStyle(
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
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Text(
                    "${ctrl.currentGame.setsWonAway} Sets",
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),

              // Server indicator
              if (ctrl.currentServer != null && ctrl.currentReceiver != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "🟢 Serving: ${ctrl.currentServer!.name} → ${ctrl.currentReceiver!.name}",
                    style: const TextStyle(fontSize: 22, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
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
        Text(
          "$score",
          style: const TextStyle(fontSize: 32, color: Colors.white),
        ),
      ],
    );
  }
}
