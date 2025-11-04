import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';
import 'package:table_tennis_scoreboard/shared/styled_button.dart';
import 'package:table_tennis_scoreboard/shared/styled_text.dart';
import 'package:table_tennis_scoreboard/theme.dart';

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
  late final MatchController _ctrl;
  Timer? _breakTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<MatchController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Register callbacks for doubles and server selection
      _ctrl.onDoublesPlayersNeeded = () {
        if (!mounted) return;
        _showDoublesPlayerPicker(context, _ctrl);
      };
      _ctrl.onServerSelectionNeeded = () {
        if (!mounted) return;
        _showServerReceiverPicker(context, _ctrl);
      };

      // Show picker on load if requested
      if (widget.showDialogOnLoad) {
        if (_ctrl.currentGame.isDoubles &&
            _ctrl.currentGame.homePlayers.isEmpty) {
          _showDoublesPlayerPicker(context, _ctrl);
        } else {
          _showServerReceiverPicker(context, _ctrl);
        }
      }
    });
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _ctrl.onDoublesPlayersNeeded = null;
    _ctrl.onServerSelectionNeeded = null;
    super.dispose();
  }

  void _startBreak() {
    _ctrl.startBreak(); // Marks break as active
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ctrl.remainingBreakTime == null ||
          _ctrl.remainingBreakTime!.inSeconds <= 0) {
        timer.cancel();
        _ctrl.endBreak();
      } else {
        _ctrl.remainingBreakTime =
            _ctrl.remainingBreakTime! - const Duration(seconds: 1);
        _ctrl.notifyListeners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();
    final bool disableButtons = ctrl.isBreakActive || !ctrl.isGameEditable;

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
                    value: ctrl,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: StyledHeading(
                        'Game ${ctrl.currentGame.order} of ${ctrl.games.length}',
                      ),
                    ),
                    Center(
                      child: StyledSubHeading(
                        'Match Score: ${ctrl.matchGamesWonHome} - ${ctrl.matchGamesWonAway}',
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
                          const SizedBox(width: 8),
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

                    // --- Points Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          style: _buttonStyle(AppColors.airForceBlue),
                          onPressed: disableButtons ? null : ctrl.addPointHome,
                          child: const Text('+ Home Point'),
                        ),
                        ElevatedButton(
                          style: _buttonStyle(AppColors.airForceBlue),
                          onPressed: disableButtons ? null : ctrl.addPointAway,
                          child: const Text('+ Away Point'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          style: _buttonStyle(AppColors.turkeyRed),
                          onPressed: disableButtons ? null : ctrl.undoPointHome,
                          child: const Text('- Home Point'),
                        ),
                        ElevatedButton(
                          style: _buttonStyle(AppColors.turkeyRed),
                          onPressed: disableButtons ? null : ctrl.undoPointAway,
                          child: const Text('- Away Point'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Break Timer & End Early Button ---
                    if (ctrl.isBreakActive)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Break: ${ctrl.remainingBreakTime?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${ctrl.remainingBreakTime?.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.yellow,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _ctrl.endBreakEarly,
                              style: _buttonStyle(AppColors.timberWhite),
                              child: const Text('End Break Early'),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Complete Match Button
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
                        style: _buttonStyle(AppColors.timberWhite),
                        child: const Text('Complete Match'),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (ctrl.currentGame.order > 1)
                  ElevatedButton(
                    onPressed: disableButtons ? null : ctrl.previousGame,
                    style: _buttonStyle(AppColors.timberWhite),
                    child: const Text('Previous'),
                  ),
                ElevatedButton(
                  onPressed: disableButtons || !ctrl.isCurrentGameCompleted
                      ? null
                      : ctrl.nextGame,
                  style: _buttonStyle(AppColors.timberWhite),
                  child: const Text('Next Game'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        child: SizedBox(
          width: double.infinity,
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
      ),
    );
  }

  // -------------------------
  // Helper Widgets
  // -------------------------
  ButtonStyle _buttonStyle(Color bgColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: AppColors.secondaryBlack,
      textStyle: GoogleFonts.oswald(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _scoreColumn(String label, int points, int sets) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          softWrap: true,
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

  // -------------------------
  // Dialogs
  // -------------------------
  void _showDoublesPlayerPicker(BuildContext context, MatchController ctrl) {
    List<Player> selectedHome = [];
    List<Player> selectedAway = [];

    showDialog(
      context: context,
      barrierDismissible: false,
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
                          if (selectedHome.length < 2) selectedHome.add(p);
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
                          if (selectedAway.length < 2) selectedAway.add(p);
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
      barrierDismissible: false,
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
                    selectedReceiver =
                        null; // Reset receiver when server changes
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Player>(
                decoration: const InputDecoration(labelText: 'Receiver'),
                value: selectedReceiver,
                items: (selectedServer == null)
                    ? []
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
