import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/shared/styled_text.dart';
import 'package:table_tennis_scoreboard/widgets/doubles_server_picker.dart';

import '../controllers/match_controller.dart';
import '../theme.dart';

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
    _ctrl = context.read<MatchController>();
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
    final ctrl = context.watch<MatchController>();

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 4,
        title: Text(
          'Match Scoreboard',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_remote, color: Colors.white),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Team names + match games
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

              const SizedBox(height: 8),

              // Game Info or Break Timer
              ctrl.isBreakActive
                  ? Column(
                      children: [
                        Text(
                          "SET BREAK",
                          style: GoogleFonts.oswald(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          "${ctrl.remainingBreakTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
                          "${ctrl.remainingBreakTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                          style: GoogleFonts.oswald(
                            fontSize: 72,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          "Game ${ctrl.currentGame.order} of ${ctrl.games.length} | Set ${ctrl.currentGame.sets.length}",
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            color: Colors.white70,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (ctrl.currentGame.homePlayers.isNotEmpty ||
                            ctrl.currentGame.awayPlayers.isNotEmpty)
                          Text(
                            "${ctrl.currentGame.homePlayers.map((p) => p.name).join(' & ')} "
                            "vs "
                            "${ctrl.currentGame.awayPlayers.map((p) => p.name).join(' & ')}",
                            style: GoogleFonts.oswald(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),

              const SizedBox(height: 16),

              // Main Scoreboard
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 32,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreColumn(
                      score: ctrl.currentSet.home,
                      color: Colors.blueAccent,
                      isServing:
                          ctrl.currentServer?.name ==
                          ctrl.currentGame.homePlayers.first.name,
                    ),
                    Text(
                      "—",
                      style: GoogleFonts.oswald(
                        fontSize: 100,
                        color: Colors.white54,
                      ),
                    ),
                    _scoreColumn(
                      score: ctrl.currentSet.away,
                      color: Colors.redAccent,
                      isServing:
                          ctrl.currentServer?.name ==
                          ctrl.currentGame.awayPlayers.first.name,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sets summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _setSummary(ctrl.currentGame.setsWonHome, Colors.blueAccent),
                  _setSummary(ctrl.currentGame.setsWonAway, Colors.redAccent),
                ],
              ),

              if (ctrl.currentServer != null && ctrl.currentReceiver != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
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
          style: GoogleFonts.oswald(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$score",
          style: GoogleFonts.oswald(
            fontSize: 34,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _scoreColumn({
    required int score,
    required Color color,
    required bool isServing,
  }) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isServing
              ? const Icon(
                  Icons.sports_tennis,
                  color: Colors.white,
                  size: 30,
                  key: ValueKey('serve'),
                )
              : const SizedBox(height: 30, key: ValueKey('empty')),
        ),
        Text(
          "$score",
          style: GoogleFonts.oswald(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _setSummary(int setsWon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        "$setsWon Sets",
        style: GoogleFonts.oswald(
          fontSize: 28,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
