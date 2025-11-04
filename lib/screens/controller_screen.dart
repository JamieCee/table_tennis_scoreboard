import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/controller/game_score.dart';
import 'package:table_tennis_scoreboard/screens/controller/points_counter.dart';
import 'package:table_tennis_scoreboard/screens/scoreboard_display.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';
import 'package:table_tennis_scoreboard/shared/styled_button.dart';
import 'package:table_tennis_scoreboard/theme.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import '../widgets/themed_dialog.dart';
import 'controller/points_buttons.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.charcoal, // dark slate base
      appBar: AppBar(
        title: const Text('Match Controller'),
        backgroundColor: AppColors.midnightBlue,
        elevation: 6,
        shadowColor: Colors.black54,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.timberWhite,
        ),
        actions: [
          IconButton(
            tooltip: "Open Display View",
            icon: const Icon(Icons.tv, color: Colors.white),
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
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.steelGray,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameAndScoreWidget(ctrl: ctrl),
                      const SizedBox(height: 16),
                      PointsCounter(ctrl: ctrl),
                      const SizedBox(height: 30),

                      // --- Buttons Section ---
                      PointsButtons(ctrl: ctrl),
                      const SizedBox(height: 24),

                      // --- Break Timer ---
                      if (ctrl.isBreakActive)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.midnightBlue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.yellowAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Break: ${ctrl.remainingBreakTime?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${ctrl.remainingBreakTime?.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                                style: GoogleFonts.orbitron(
                                  fontSize: 24,
                                  color: Colors.yellowAccent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StyledIconButton(
                                onPressed: _ctrl.endBreakEarly,
                                icon: const Icon(
                                  Icons.timer_off_outlined,
                                  color: Colors.black,
                                ),
                                color: Colors.yellowAccent,
                                child: const Text(
                                  'End Break Early',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // --- Complete Match Button ---
                      if (ctrl.games.last.setsWonHome == 3 ||
                          ctrl.games.last.setsWonAway == 3)
                        StyledIconButton(
                          color: AppColors.emeraldGreen,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MatchScorecardScreen(ctrl: ctrl),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.emoji_events_outlined,
                            color: Colors.black,
                          ),
                          child: const Text(
                            'Complete Match',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.midnightBlue,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: SizedBox(
            width: double.infinity, // full width
            height: 56, // taller so text is comfortably visible
            child: ElevatedButton.icon(
              onPressed: () {
                // reset app logic
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const TeamSetupScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              label: const Text(
                "Reset App",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turkeyRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
      foregroundColor: AppColors.white,
      textStyle: GoogleFonts.oswald(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
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
        builder: (context, setState) => ThemedDialog(
          title: 'Select Doubles Players',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _teamChipSection(
                context,
                'Home Team (Select 2)',
                ctrl.home.players,
                selectedHome,
                setState,
                Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              _teamChipSection(
                context,
                'Away Team (Select 2)',
                ctrl.away.players,
                selectedAway,
                setState,
                Colors.redAccent,
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm'),
              onPressed: (selectedHome.length == 2 && selectedAway.length == 2)
                  ? () {
                      ctrl.setDoublesPlayers(selectedHome, selectedAway);
                      Navigator.pop(context);
                      _showServerReceiverPicker(context, ctrl);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamChipSection(
    BuildContext context,
    String title,
    List<Player> players,
    List<Player> selectedPlayers,
    void Function(void Function()) setState,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.robotoCondensed(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          children: players.map((p) {
            final isSelected = selectedPlayers.contains(p);
            return ChoiceChip(
              label: Text(p.name),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedColor: color,
              backgroundColor: Colors.white10,
              side: BorderSide(color: color.withOpacity(0.4)),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (selectedPlayers.length < 2) selectedPlayers.add(p);
                  } else {
                    selectedPlayers.remove(p);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showServerReceiverPicker(BuildContext context, MatchController ctrl) {
    Player? selectedServer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => ThemedDialog(
          title: 'Select Server',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose the player who will serve first:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _serverSelectSection(
                'Home Team',
                ctrl.currentGame.homePlayers,
                selectedServer,
                (p) => setDialogState(() => selectedServer = p),
                Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              _serverSelectSection(
                'Away Team',
                ctrl.currentGame.awayPlayers,
                selectedServer,
                (p) => setDialogState(() => selectedServer = p),
                Colors.redAccent,
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(
                selectedServer == null
                    ? 'Confirm'
                    : 'Start: ${selectedServer!.name} serves',
              ),
              onPressed: selectedServer == null
                  ? null
                  : () {
                      final receiver =
                          ctrl.currentGame.homePlayers.contains(selectedServer)
                          ? ctrl.currentGame.awayPlayers.first
                          : ctrl.currentGame.homePlayers.first;

                      ctrl.setServer(selectedServer, receiver);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverSelectSection(
    String label,
    List<Player> players,
    Player? selectedServer,
    void Function(Player) onSelected,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          children: players.map((p) {
            final isSelected = selectedServer == p;
            return ChoiceChip(
              label: Text(p.name),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedColor: color,
              backgroundColor: Colors.white10,
              side: BorderSide(color: color.withOpacity(0.4)),
              onSelected: (_) => onSelected(p),
            );
          }).toList(),
        ),
      ],
    );
  }
}
