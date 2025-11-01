import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';
import 'package:table_tennis_scoreboard/shared/styled_button.dart';
import 'package:table_tennis_scoreboard/shared/styled_text.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import 'match_scorecard_screen.dart';

class ControllerScreen extends StatefulWidget {
  final bool showDialogOnLoad;
  const ControllerScreen({super.key, this.showDialogOnLoad = false});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the execution until after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<MatchController>();

      // Register the callbacks that the controller will use to show dialogs.
      ctrl.onDoublesPlayersNeeded = () =>
          _showDoublesPlayerPicker(context, ctrl);
      ctrl.onServerSelectionNeeded = () =>
          _showServerReceiverPicker(context, ctrl);

      if (widget.showDialogOnLoad) {
        if (ctrl.currentGame.isDoubles &&
            ctrl.currentGame.homePlayers.isEmpty) {
          _showDoublesPlayerPicker(context, ctrl);
        } else {
          _showServerReceiverPicker(context, ctrl);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Controller'),
        backgroundColor: Colors.grey[900],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.tv),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: Provider.of<MatchController>(context, listen: false),
                    child: const ScoreboardDisplayScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: StyledHeading(
                  'Game ${ctrl.currentGame.order} of ${ctrl.games.length}',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _scoreColumn(
                        ctrl.currentGame.homePlayers
                            .map((p) => p.name)
                            .join(" & "),
                        ctrl.currentSet.home,
                        ctrl.currentGame.setsWonHome,
                      ),
                    ),
                    const SizedBox(width: 8), // small spacing between columns
                    Expanded(
                      child: _scoreColumn(
                        ctrl.currentGame.awayPlayers
                            .map((p) => p.name)
                            .join(" & "),
                        ctrl.currentSet.away,
                        ctrl.currentGame.setsWonAway,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.addPointHome : null,
                    child: const Text('+ Home Point'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.addPointAway : null,
                    child: const Text('+ Away Point'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.undoPointHome : null,
                    child: const Text('- Home Point'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.undoPointAway : null,
                    child: const Text('- Away Point'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (ctrl.currentGame.order >
                          1) // only show if not the first game
                        ElevatedButton(
                          onPressed: ctrl.previousGame,
                          child: StyledButtonText('Previous'),
                        ),
                      ElevatedButton(
                        onPressed: ctrl.isCurrentGameCompleted
                            ? ctrl.nextGame
                            : null,
                        child: const StyledButtonText('Next Game'),
                      ),
                    ],
                  ),
                  if (ctrl.games.last.setsWonHome == 3 ||
                      ctrl.games.last.setsWonAway == 3)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchScorecardScreen(ctrl: ctrl),
                          ),
                        );
                      },
                      child: const Text('Complete Match'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: StyledSubHeading(
                  'Match Score: ${ctrl.matchGamesWonHome} - ${ctrl.matchGamesWonAway}',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        child: StyledIconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TeamSetupScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
          child: StyledButtonText("Reset App"),
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int points, int sets) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // ✅ centers multiline doubles names
          softWrap: true, // ✅ allows wrapping for long names
          overflow: TextOverflow.visible,
        ),
        Text('Points: $points', style: const TextStyle(fontSize: 22)),
        Text(
          'Sets: $sets',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  // Widget _scoreColumn(String label, int points, int sets) {
  //   return Column(
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //       ),
  //       Text('Points: $points', style: const TextStyle(fontSize: 22)),
  //       Text(
  //         'Sets: $sets',
  //         style: const TextStyle(fontSize: 18, color: Colors.grey),
  //       ),
  //     ],
  //   );
  // }

  void _showDoublesPlayerPicker(BuildContext context, MatchController ctrl) {
    List<Player> selectedHome = [];
    List<Player> selectedAway = [];

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Doubles Players'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Home Team (Select 2)'),
              Wrap(
                spacing: 8.0,
                children: ctrl.home.players.map((p) {
                  final isSelected = selectedHome.contains(p);
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (selectedHome.length < 2) {
                            selectedHome.add(p);
                          }
                        } else {
                          selectedHome.remove(p);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Away Team (Select 2)'),
              Wrap(
                spacing: 8.0,
                children: ctrl.away.players.map((p) {
                  final isSelected = selectedAway.contains(p);
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (selectedAway.length < 2) {
                            selectedAway.add(p);
                          }
                        } else {
                          selectedAway.remove(p);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: (selectedHome.length == 2 && selectedAway.length == 2)
                  ? () {
                      ctrl.setDoublesPlayers(selectedHome, selectedAway);
                      Navigator.pop(context);
                      // After setting players, immediately ask for server.
                      _showServerReceiverPicker(context, ctrl);
                    }
                  : null,
              child: const Text('Set Players'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerReceiverPicker(BuildContext context, MatchController ctrl) {
    Player? selectedServer;
    Player? selectedReceiver;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Server and Receiver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Player>(
                decoration: const InputDecoration(labelText: 'Server'),
                value: selectedServer,
                items:
                    [
                          ...ctrl.currentGame.homePlayers,
                          ...ctrl.currentGame.awayPlayers,
                        ]
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.name)),
                        )
                        .toList(),
                onChanged: (p) {
                  setState(() {
                    selectedServer = p;
                    // When server changes, the receiver must be reset to avoid invalid pairings.
                    selectedReceiver = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Player>(
                decoration: const InputDecoration(labelText: 'Receiver'),
                value: selectedReceiver,
                items: (selectedServer == null)
                    ? [] // No receiver options until server is picked
                    // Receiver must be from the opposing team.
                    : (ctrl.currentGame.homePlayers.contains(selectedServer!)
                              ? ctrl.currentGame.awayPlayers
                              : ctrl.currentGame.homePlayers)
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                onChanged: (p) => setState(() => selectedReceiver = p),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: (selectedServer != null && selectedReceiver != null)
                  ? () {
                      ctrl.setServer(selectedServer, selectedReceiver);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }
}
