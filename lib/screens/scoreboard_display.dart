import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import '../screens/controller_screen.dart';
import '../theme.dart';
import '../widgets/doubles_server_picker.dart';
import '../widgets/themed_dialog.dart';

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

    // --- Hook up callbacks so dialogs appear automatically ---
    _ctrl.onDoublesPlayersNeeded = () => _showDoublesPicker();
    _ctrl.onServerSelectionNeeded = () => _showServerPicker();
  }

  @override
  void dispose() {
    _ctrl.onDoublesPlayersNeeded = null;
    _ctrl.onServerSelectionNeeded = null;
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // Dialogs
  // ----------------------------------------------------------------------

  void _showDoublesPicker() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: _ctrl,
        child: const DoublesServerPicker(),
      ),
    );
  }

  void _showServerPicker() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    Player? selectedServer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => ThemedDialog(
          title: 'Select Server',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose the player who will serve first:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _ctrl.currentGame.homePlayers
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    setState(() => selectedServer = p),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedServer == p
                                      ? Colors.blueAccent
                                      : Colors.white10,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(45),
                                ),
                                child: Text(p.name),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _ctrl.currentGame.awayPlayers
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    setState(() => selectedServer = p),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedServer == p
                                      ? Colors.redAccent
                                      : Colors.white10,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(45),
                                ),
                                child: Text(p.name),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton.icon(
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
                            _ctrl.currentGame.homePlayers.contains(
                              selectedServer,
                            )
                            ? _ctrl.currentGame.awayPlayers.first
                            : _ctrl.currentGame.homePlayers.first;

                        _ctrl.setServer(selectedServer, receiver);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------

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
              ctrl.isBreakActive ? _breakTimer(ctrl) : _gameInfo(ctrl),

              const SizedBox(height: 2),

              // Main Scoreboard
              _mainScoreboard(ctrl),

              const SizedBox(height: 2),

              // Sets summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _setSummary(ctrl.currentGame.setsWonHome, Colors.blueAccent),
                  _setSummary(ctrl.currentGame.setsWonAway, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 20),

              // Footer
              _matchOverviewFooter(ctrl),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Helper Widgets
  // ----------------------------------------------------------------------

  Widget _breakTimer(MatchController ctrl) {
    return Column(
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
    );
  }

  Widget _gameInfo(MatchController ctrl) {
    final homePlayers = ctrl.currentGame.homePlayers;
    final awayPlayers = ctrl.currentGame.awayPlayers;

    final homeText = homePlayers.isNotEmpty
        ? homePlayers.map((p) => p.name).join(' & ')
        : '—';
    final awayText = awayPlayers.isNotEmpty
        ? awayPlayers.map((p) => p.name).join(' & ')
        : '—';

    return Column(
      children: [
        Text(
          "$homeText vs $awayText",
          style: GoogleFonts.oswald(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (homePlayers.isEmpty || awayPlayers.isEmpty)
          const SizedBox(height: 8),
        if (homePlayers.isEmpty || awayPlayers.isEmpty)
          Text(
            "(Waiting for player selection...)",
            style: GoogleFonts.oswald(
              fontSize: 16,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _mainScoreboard(MatchController ctrl) {
    final homePlayers = ctrl.currentGame.homePlayers;
    final awayPlayers = ctrl.currentGame.awayPlayers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreColumn(
            score: ctrl.currentSet.home,
            color: Colors.blueAccent,
            isServing:
                homePlayers.isNotEmpty &&
                ctrl.currentServer?.name == homePlayers.first.name,
          ),
          Text(
            "—",
            style: GoogleFonts.oswald(fontSize: 100, color: Colors.white54),
          ),
          _scoreColumn(
            score: ctrl.currentSet.away,
            color: Colors.redAccent,
            isServing:
                awayPlayers.isNotEmpty &&
                ctrl.currentServer?.name == awayPlayers.first.name,
          ),
        ],
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

  Widget _matchOverviewFooter(MatchController ctrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _footerItem(
            icon: Icons.sports_tennis,
            label: "Next Serve",
            value: ctrl.currentServer?.name ?? "--",
          ),
          _footerItem(
            icon: Icons.grid_view_rounded,
            label: "Game/Set",
            value:
                "G${ctrl.currentGame.order} / S${ctrl.currentGame.sets.length}",
          ),
        ],
      ),
    );
  }

  Widget _footerItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 14,
            color: Colors.white54,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
