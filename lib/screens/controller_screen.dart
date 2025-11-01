import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';

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
              Text(
                'Game ${ctrl.currentGame.order} of ${ctrl.games.length}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (ctrl.currentGame.homePlayers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${ctrl.currentGame.homePlayers.map((p) => p.name).join(" & ")} '
                    'vs ${ctrl.currentGame.awayPlayers.map((p) => p.name).join(" & ")}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _scoreColumn(
                    'Home',
                    ctrl.currentSet.home,
                    ctrl.currentGame.setsWonHome,
                  ),
                  _scoreColumn(
                    'Away',
                    ctrl.currentSet.away,
                    ctrl.currentGame.setsWonAway,
                  ),
                ],
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
                  if (ctrl.currentGame.order >
                      1) // 👈 only show if not the first game
                    ElevatedButton(
                      onPressed: ctrl.previousGame,
                      child: const Text('Previous Game'),
                    ),
                  ElevatedButton(
                    onPressed: ctrl.isCurrentGameCompleted
                        ? ctrl.nextGame
                        : null,
                    child: const Text('Next Game'),
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
                child: Text(
                  'Match Score: ${ctrl.matchGamesWonHome} - ${ctrl.matchGamesWonAway}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Reset App"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const TeamSetupScreen()),
                (route) => false,
              );

              // By using a Future, we delay the reset until the next event
              // loop, which allows the navigation to complete and this screen
              // to be disposed of before the controller's state changes.
              // Future(() => ctrl.reset());
            },
          ),
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int points, int sets) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('Points: $points', style: const TextStyle(fontSize: 22)),
        Text(
          'Sets: $sets',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

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
