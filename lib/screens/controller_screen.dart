import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import 'match_scorecard_screen.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  void _showServeDialog(BuildContext context, MatchController ctrl) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Select First Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  ctrl.setServer(
                    ctrl.currentGame.homePlayers.first,
                    ctrl.currentGame.awayPlayers.first,
                  );
                  Navigator.pop(context);
                },
                child: Text('${ctrl.home.name}'),
              ),
              TextButton(
                onPressed: () {
                  ctrl.setServer(
                    ctrl.currentGame.awayPlayers.first,
                    ctrl.currentGame.homePlayers.first,
                  );
                  Navigator.pop(context);
                },
                child: Text('${ctrl.away.name}'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServerReceiverDialog(BuildContext context, MatchController ctrl) {
    Player? selectedServer;
    Player? selectedReceiver;

    showDialog(
      context: context,
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
                    ].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.name));
                    }).toList(),
                onChanged: (p) => setState(() => selectedServer = p),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Player>(
                decoration: const InputDecoration(labelText: 'Receiver'),
                value: selectedReceiver,
                items: selectedServer == null
                    ? [] // no options until server selected
                    : (ctrl.currentGame.homePlayers.contains(selectedServer)
                              ? ctrl
                                    .currentGame
                                    .awayPlayers // receiver must be from opposite team
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedServer != null && selectedReceiver != null)
                  ? () {
                      if (ctrl.currentGame.isDoubles) {
                        ctrl.setDoublesStartingServer(
                          selectedServer!,
                          selectedReceiver!,
                        );
                      } else {
                        ctrl.setServer(selectedServer!, selectedReceiver!);
                      }
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

  @override
  void initState() {
    super.initState();

    // Wait until the first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Provider.of<MatchController>(context, listen: false);

      // Trigger server/doubles player picker for the first game
      if (ctrl.currentGame.isDoubles &&
          ctrl.currentGame.homePlayers.length != 1) {
        if (ctrl.onDoublesPlayersNeeded != null)
          ctrl.onServerSelectionNeeded!();
      } else {
        if (ctrl.onServerSelectionNeeded != null)
          ctrl.onServerSelectionNeeded!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();

    // Register callbacks for auto dialogs
    ctrl.onDoublesPlayersNeeded = () => _showDoublesPlayerPicker(context, ctrl);
    ctrl.onServerSelectionNeeded = () =>
        _showServerReceiverPicker(context, ctrl);

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
              ),
              Text(
                '${ctrl.currentGame.homePlayers.map((p) => p.name).join(" & ")} '
                'vs ${ctrl.currentGame.awayPlayers.map((p) => p.name).join(" & ")}',
                style: Theme.of(context).textTheme.titleMedium,
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

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.addPointHome : null,
                    child: Text('+ Home Point'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.addPointAway : null,
                    child: Text('+ Away Point'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.undoPointHome : null,
                    child: Text('- Home Point'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isGameEditable ? ctrl.undoPointAway : null,
                    child: Text('- Away Point'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: ctrl.previousGame,
                    child: Text('Previous Game'),
                  ),
                  ElevatedButton(
                    onPressed: ctrl.isCurrentGameCompleted
                        ? ctrl.nextGame
                        : null,
                    child: Text('Next Game'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showServerReceiverDialog(context, ctrl),
                    child: const Text('Set Server/Receiver'),
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
            icon: Icon(Icons.refresh),
            label: Text("Reset App"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () {
              ctrl.reset(); // Clear state
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamSetupScreen(),
                ), // replace with your actual team setup screen
                (route) => false, // removes all previous routes
              );
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('Points: $points', style: TextStyle(fontSize: 22)),
        Text('Sets: $sets', style: TextStyle(fontSize: 18, color: Colors.grey)),
      ],
    );
  }

  void _showDoublesPlayerPicker(BuildContext context, MatchController ctrl) {
    List<Player> selectedHome = [];
    List<Player> selectedAway = [];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Doubles Players'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Home Team'),
              Wrap(
                children: ctrl.home.players.map((p) {
                  final isSelected = selectedHome.contains(p);
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        if (selectedHome.length < 2) selectedHome.add(p);
                      } else {
                        selectedHome.remove(p);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Away Team'),
              Wrap(
                children: ctrl.away.players.map((p) {
                  final isSelected = selectedAway.contains(p);
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        if (selectedAway.length < 2) selectedAway.add(p);
                      } else {
                        selectedAway.remove(p);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedHome.length == 2 && selectedAway.length == 2
                  ? () {
                      // Update the current game with selected doubles players
                      ctrl.currentGame.homePlayers
                        ..clear()
                        ..addAll(selectedHome);
                      ctrl.currentGame.awayPlayers
                        ..clear()
                        ..addAll(selectedAway);

                      Navigator.pop(context);

                      // Trigger server selection for this game
                      if (ctrl.onServerSelectionNeeded != null) {
                        ctrl.onServerSelectionNeeded!();
                      }
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
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Server and Receiver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SERVER DROPDOWN
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
                    // Reset receiver if it was the same as server
                    if (selectedReceiver == selectedServer)
                      selectedReceiver = null;
                  });
                },
              ),

              const SizedBox(height: 12),

              // RECEIVER DROPDOWN
              DropdownButtonFormField<Player>(
                decoration: const InputDecoration(labelText: 'Receiver'),
                value: selectedReceiver,
                items:
                    [
                          ...ctrl.currentGame.homePlayers,
                          ...ctrl.currentGame.awayPlayers,
                        ]
                        .where(
                          (p) => p != selectedServer,
                        ) // exclude selected server
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedServer != null && selectedReceiver != null
                  ? () {
                      if (ctrl.currentGame.isDoubles) {
                        ctrl.setDoublesStartingServer(
                          selectedServer!,
                          selectedReceiver!,
                        );
                      } else {
                        ctrl.setServer(selectedServer!, selectedReceiver!);
                      }
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
