import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/screens/home_screen.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import '../screens/controller_screen.dart';
import '../theme.dart';
import '../widgets/doubles_server_picker.dart';
import '../widgets/scoreboard_transition.dart';
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

    _ctrl.onMatchDeleted = () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    };

    if (!_ctrl.isObserver) {
      _ctrl.onDoublesPlayersNeeded = () => _showDoublesPicker();
      _ctrl.onServerSelectionNeeded = () => _showServerPicker();
    }
  }

  @override
  void dispose() {
    _ctrl.onMatchDeleted = null;
    if (!_ctrl.isObserver) {
      _ctrl.onDoublesPlayersNeeded = null;
      _ctrl.onServerSelectionNeeded = null;
    }
    super.dispose();
  }

  void _showDoublesPicker() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
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
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
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

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: ctrl.isObserver
          ? null
          : AppBar(
              backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.4),
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _teamBlock(
                        ctrl.home.name,
                        ctrl.matchGamesWonHome,
                        Colors.blueAccent,
                        usedTimeout: ctrl.currentGame.homeTimeoutUsed,
                      ),
                      _teamBlock(
                        ctrl.away.name,
                        ctrl.matchGamesWonAway,
                        Colors.redAccent,
                        usedTimeout: ctrl.currentGame.awayTimeoutUsed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ctrl.isTimeoutActive
                      ? _timeoutTimer(ctrl)
                      : ctrl.isBreakActive
                      ? _breakTimer(ctrl)
                      : _gameInfo(ctrl),
                  const SizedBox(height: 28),
                  _mainScoreboard(ctrl),
                  const SizedBox(height: 28),
                  _setScores(ctrl),
                  const SizedBox(height: 28),
                  _matchOverviewFooter(ctrl),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (ctrl.isTransitioning && ctrl.isNextGameReady)
            ScoreTransitionOverlay(
              gameNumber: _ctrl.currentGame.order,
              totalGames: _ctrl.games.length,
              homeNames: _ctrl.home.name,
              awayNames: _ctrl.away.name,
              homeScore:
                  (ctrl.lastGameResult?['homeScore'] as num?)?.toInt() ?? 0,
              awayScore:
                  (ctrl.lastGameResult?['awayScore'] as num?)?.toInt() ?? 0,
              setScores:
                  (ctrl.lastGameResult?['setScores'] as List<dynamic>?)
                      ?.map((s) => Map<String, int>.from(s as Map))
                      .toList() ??
                  [],
              nextHomeNames: ctrl.matchType == MatchType.singles
                  ? ctrl.nextGame?.homePlayers.first.name
                  : ctrl.nextGame?.homePlayers.map((p) => p.name).join(' & '),
              nextAwayNames: ctrl.matchType == MatchType.singles
                  ? ctrl.nextGame?.awayPlayers.first.name
                  : ctrl.nextGame?.awayPlayers.map((p) => p.name).join(' & '),
              onContinue: () => _ctrl.startNextGame(),
            ),
        ],
      ),
    );
  }

  Widget _breakTimer(MatchController ctrl) {
    final remainingTime = ctrl.remainingBreakTime ?? Duration.zero;
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
          "${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
          style: GoogleFonts.oswald(
            fontSize: 72,
            color: Colors.greenAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _timeoutTimer(MatchController ctrl) {
    final remainingTime = ctrl.remainingTimeoutTime ?? Duration.zero;
    return Column(
      children: [
        Text(
          ctrl.timeoutCalledByHome ? "HOME TIMEOUT" : "AWAY TIMEOUT",
          style: GoogleFonts.oswald(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        Text(
          "${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
          style: GoogleFonts.oswald(
            fontSize: 72,
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _gameInfo(MatchController ctrl) {
    if (ctrl.matchType == MatchType.singles) {
      return Text(
        "Best of ${ctrl.setsToWin == 3 ? 5 : 7} sets",
        style: GoogleFonts.oswald(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    }

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

    bool isHomeServing = false;
    if (ctrl.currentServer != null && homePlayers.isNotEmpty) {
      isHomeServing = homePlayers.any(
        (p) => p.name == ctrl.currentServer!.name,
      );
    }

    bool isAwayServing = false;
    if (ctrl.currentServer != null && awayPlayers.isNotEmpty) {
      isAwayServing = awayPlayers.any(
        (p) => p.name == ctrl.currentServer!.name,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10.withAlpha(5),
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
            isServing: isHomeServing,
          ),
          const SizedBox(width: 50),
          _scoreColumn(
            score: ctrl.currentSet.away,
            color: Colors.redAccent,
            isServing: isAwayServing,
          ),
        ],
      ),
    );
  }

  Widget _teamBlock(
    String name,
    int score,
    Color color, {
    bool usedTimeout = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
            if (usedTimeout)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.timer, color: Colors.purpleAccent, size: 18),
              ),
          ],
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

  Widget _setScores(MatchController ctrl) {
    final completedSets = ctrl.currentGame.sets.where((s) {
      final isFinished =
          (s.home >= ctrl.pointsToWin || s.away >= ctrl.pointsToWin) &&
          (s.home - s.away).abs() >= 2;
      return isFinished;
    }).toList();

    if (completedSets.isEmpty) {
      return const SizedBox(height: 60); // Keep layout consistent
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: completedSets.map((set) {
        return SizedBox(
          width: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.midnightBlue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.midnightBlue, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${set.home}',
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${set.away}',
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _matchOverviewFooter(MatchController ctrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
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
                "G${_ctrl.currentGame.order} / S${_ctrl.currentGame.sets.length}",
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
