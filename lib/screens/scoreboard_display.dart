import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/match/match_bloc.dart';
import '../models/player.dart';
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
  @override
  void initState() {
    super.initState();
  }

  void _showDoublesPicker(MatchBloc bloc) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DoublesServerPicker(),
    );
  }

  void _showServerPicker(
    MatchBloc bloc,
    List<Player> homePlayers,
    List<Player> awayPlayers,
  ) {
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
                      children: homePlayers
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
                      children: awayPlayers
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
                        final receiver = homePlayers.contains(selectedServer)
                            ? awayPlayers.first
                            : homePlayers.first;
                        context.read<MatchBloc>().add(
                          SetDoublesServer(
                            server: selectedServer!,
                            receiver: receiver,
                          ),
                        );
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

  String _winnerName(MatchState state) {
    final homeWon = state.matchGamesWonHome > state.matchGamesWonAway;
    return homeWon ? state.homeTeam.name : state.awayTeam.name;
  }

  String _finalScore(MatchState state) {
    return "${state.matchGamesWonHome} – ${state.matchGamesWonAway}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.currentGame == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final homePlayers = state.currentGame!.homePlayers;
        final awayPlayers = state.currentGame!.awayPlayers;

        final isObserver = false; // derive if needed
        final isComplete = state.isMatchOver;

        return Scaffold(
          backgroundColor: AppColors.charcoal,
          appBar: isObserver
              ? null
              : AppBar(
                  backgroundColor: AppColors.purple.withValues(alpha: 0.4),
                  elevation: 6,
                  title: Text(
                    'Match Scoreboard',
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      if (isComplete) _finalResultHeader(state),

                      if (!isComplete) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _teamBlock(
                              homePlayers.map((p) => p.name).join(' & '),
                              state.matchGamesWonHome,
                              Colors.blueAccent,
                              usedTimeout: state.currentGame!.homeTimeoutUsed,
                            ),
                            Expanded(child: _gameInfo(state)),
                            _teamBlock(
                              awayPlayers.map((p) => p.name).join(' & '),
                              state.matchGamesWonAway,
                              Colors.redAccent,
                              usedTimeout: state.currentGame!.awayTimeoutUsed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        state.isTimeoutActive
                            ? _timeoutTimer(state)
                            : state.isBreakActive
                            ? _breakTimer(state)
                            : const SizedBox.shrink(),
                        const SizedBox(height: 15),
                        _mainScoreboard(state),
                        const SizedBox(height: 10),
                        _setScores(state),
                        const SizedBox(height: 10),
                        _matchOverviewFooter(state),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.isTransitioning && state.isNextGameReady)
                ScoreTransitionOverlay(
                  gameNumber: state.currentGame!.order,
                  totalGames: state.games.length,
                  homeNames: state.currentGame!.homePlayers
                      .map((p) => p.name)
                      .join(' & '),
                  awayNames: state.currentGame!.awayPlayers
                      .map((p) => p.name)
                      .join(' & '),
                  homeScore:
                      (state.lastGameResult?['homeScore'] as num?)?.toInt() ??
                      0,
                  awayScore:
                      (state.lastGameResult?['awayScore'] as num?)?.toInt() ??
                      0,
                  setScores:
                      (state.lastGameResult?['setScores'] as List<dynamic>?)
                          ?.map((s) => Map<String, int>.from(s as Map))
                          .toList() ??
                      [],
                  nextHomeNames: state.matchType == MatchType.singles
                      ? state.nextGame?.homePlayers.first.name
                      : state.nextGame?.homePlayers
                            .map((p) => p.name)
                            .join(' & '),
                  nextAwayNames: state.matchType == MatchType.singles
                      ? state.nextGame?.awayPlayers.first.name
                      : state.nextGame?.awayPlayers
                            .map((p) => p.name)
                            .join(' & '),
                  onContinue: () {
                    context.read<MatchBloc>().add(StartNextGame());
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------- Helper Widgets ------------------- //

  Widget _breakTimer(MatchState state) {
    final remainingTime = state.remainingBreakTime ?? Duration.zero;
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
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _timeoutTimer(MatchState state) {
    final remainingTime = state.remainingTimeoutTime ?? Duration.zero;
    return Column(
      children: [
        Text(
          state.timeoutCalledByHome ? "HOME TIMEOUT" : "AWAY TIMEOUT",
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

  Widget _gameInfo(MatchState state) {
    if (state.matchType == MatchType.singles ||
        state.matchType == MatchType.handicap) {
      return Text(
        "Best of ${(state.setsToWin * 2) - 1} sets",
        style: GoogleFonts.oswald(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    }

    final homeText = state.currentGame!.homePlayers.isNotEmpty
        ? state.currentGame!.homePlayers.map((p) => p.name).join(' & ')
        : '—';
    final awayText = state.currentGame!.awayPlayers.isNotEmpty
        ? state.currentGame!.awayPlayers.map((p) => p.name).join(' & ')
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
        if (state.currentGame!.homePlayers.isEmpty ||
            state.currentGame!.awayPlayers.isEmpty)
          const SizedBox(height: 8),
        if (state.currentGame!.homePlayers.isEmpty ||
            state.currentGame!.awayPlayers.isEmpty)
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

  Widget _finalResultHeader(MatchState state) {
    final isHomeWinner = state.matchGamesWonHome > state.matchGamesWonAway;

    return Column(
      children: [
        Text(
          "MATCH COMPLETE",
          style: GoogleFonts.oswald(
            fontSize: 22,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _winnerName(state),
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: isHomeWinner ? Colors.blueAccent : Colors.redAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Wins ${_finalScore(state)}",
          style: GoogleFonts.oswald(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        _setScores(state, isComplete: true),
      ],
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

  Widget _mainScoreboard(MatchState state) {
    final homePlayers = state.currentGame!.homePlayers;
    final awayPlayers = state.currentGame!.awayPlayers;

    bool isHomeServing =
        state.currentServer != null &&
        homePlayers.contains(state.currentServer);

    bool isAwayServing =
        state.currentServer != null &&
        awayPlayers.contains(state.currentServer);

    bool? homeWonLastSet;
    if (state.isBreakActive) {
      final lastCompletedSet = state.currentGame!.sets.lastWhereOrNull(
        (s) =>
            (s.home >= state.pointsToWin || s.away >= state.pointsToWin) &&
            (s.home - s.away).abs() >= 2,
      );
      if (lastCompletedSet != null) {
        homeWonLastSet = lastCompletedSet.home > lastCompletedSet.away;
      }
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
            score: state.currentSet!.home,
            color: Colors.blueAccent,
            isServing: isHomeServing,
            isWinner: homeWonLastSet == true,
          ),
          _scoreColumn(
            score: state.currentSet!.away,
            color: Colors.redAccent,
            isServing: isAwayServing,
            isWinner: homeWonLastSet == false,
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn({
    required int score,
    required Color color,
    required bool isServing,
    bool isWinner = false,
  }) {
    final winnerDecoration = BoxDecoration(
      border: Border.all(color: color, width: 4),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 15,
          spreadRadius: 5,
        ),
      ],
    );

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
        Container(
          decoration: isWinner ? winnerDecoration : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            score.toString(),
            style: GoogleFonts.oswald(
              fontSize: 100,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _setScores(MatchState state, {bool isComplete = false}) {
    final completedSets = state.currentGame!.sets.where((set) {
      // A set is complete if a player has reached the required points AND has a 2-point lead.
      final bool isSetFinished =
          (set.home >= state.pointsToWin || set.away >= state.pointsToWin) &&
          (set.home - set.away).abs() >= 2;

      // If the match is complete, show all finished sets. Otherwise, exclude the current one.
      return isSetFinished && (isComplete || set != state.currentSet);
    }).toList();

    if (completedSets.isEmpty) return const SizedBox(height: 60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: completedSets.map((set) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12, width: 1.5),
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

  Widget _matchOverviewFooter(MatchState state) {
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
            value: state.currentServer?.name ?? "--",
          ),
          _footerItem(
            icon: Icons.grid_view_rounded,
            label: "Game/Set",
            value:
                "G${state.currentGame!.order} / S${state.currentGame!.sets.length}",
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
