import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/shared/styled_text.dart';
import 'package:table_tennis_scoreboard/widgets/doubles_server_picker.dart';

import '../controllers/match_controller.dart';

class ScoreboardDisplayScreen extends StatefulWidget {
  const ScoreboardDisplayScreen({super.key});

  @override
  State<ScoreboardDisplayScreen> createState() =>
      _ScoreboardDisplayScreenState();
}

class _ScoreboardDisplayScreenState extends State<ScoreboardDisplayScreen> {
  late final MatchController _ctrl;

  @override
  void initState() {
    super.initState();

    // Assign controller once
    _ctrl = context.read<MatchController>();

    // Set picker callbacks after the first frame
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _ctrl.onDoublesPlayersNeeded = _showPicker;
    //   _ctrl.onServerSelectionNeeded = _showPicker;
    //
    //   // Show picker if needed for the first game
    //   if (_ctrl.currentServer == null) {
    //     _showPicker();
    //   }
    // });
  }

  @override
  void dispose() {
    _ctrl.onDoublesPlayersNeeded = null;
    _ctrl.onServerSelectionNeeded = null;
    super.dispose();
  }

  void _showPicker() {
    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: _ctrl,
          child: const DoublesServerPicker(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context
        .watch<MatchController>(); // rebuilds on notifyListeners()

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
                    value: ctrl,
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

              // Break timer
              if (ctrl.isBreakActive)
                Column(
                  children: [
                    const Text(
                      "Set Break",
                      style: TextStyle(fontSize: 36, color: Colors.white70),
                    ),
                    Text(
                      "${ctrl.remainingBreakTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
                      "${ctrl.remainingBreakTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 72, color: Colors.white),
                    ),
                  ],
                )
              else
                // Game info
                Column(
                  children: [
                    Text(
                      "Game ${ctrl.currentGame.order} of ${ctrl.games.length} | "
                      "Set ${ctrl.currentGame.sets.length}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white54,
                      ),
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
                  // Home Column
                  Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child:
                            (ctrl.currentServer != null &&
                                ctrl.currentServer!.name ==
                                    ctrl.currentGame.homePlayers.first.name)
                            ? const Icon(
                                Icons.sports_tennis,
                                key: ValueKey('homeBall'),
                                size: 32,
                                color: Colors.white,
                              )
                            : const SizedBox(
                                key: ValueKey('homeEmpty'),
                                height: 32,
                              ),
                      ),
                      Text(
                        "${ctrl.currentSet.home}",
                        style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "—",
                    style: TextStyle(fontSize: 100, color: Colors.white54),
                  ),

                  // Away Column
                  Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child:
                            (ctrl.currentServer != null &&
                                ctrl.currentServer!.name ==
                                    ctrl.currentGame.awayPlayers.first.name)
                            ? const Icon(
                                Icons.sports_tennis,
                                key: ValueKey('awayBall'),
                                size: 32,
                                color: Colors.white,
                              )
                            : const SizedBox(
                                key: ValueKey('awayEmpty'),
                                height: 32,
                              ),
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
                  child: StyledSubHeading(
                    '${ctrl.currentServer!.name} is serving',
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
