import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';
import 'package:table_tennis_scoreboard/models/game.dart';
import 'package:table_tennis_scoreboard/models/set_score.dart';

import '../theme.dart';
import '../widgets/scoreboard_transition.dart';

class ScoreboardDisplayScreen extends StatelessWidget {
  const ScoreboardDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final bloc = context.read<MatchControllerBloc>();
        final game = state.currentGame;
        final currentSet = state.currentSet;

        if (game == null || currentSet == null) {
          return const Scaffold(
            backgroundColor: Colors.black87,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Determine home/away labels
        String homeLabel = game.homePlayers.isNotEmpty
            ? game.homePlayers.map((p) => p.name).join(' & ')
            : state.home.players.map((p) => p.name).join(' & ');

        String awayLabel = game.awayPlayers.isNotEmpty
            ? game.awayPlayers.map((p) => p.name).join(' & ')
            : state.away.players.map((p) => p.name).join(' & ');

        // Who is serving
        bool isHomeServing =
            state.currentServer != null &&
            game.homePlayers.any((p) => p.name == state.currentServer!.name);

        bool isAwayServing =
            state.currentServer != null &&
            game.awayPlayers.any((p) => p.name == state.currentServer!.name);

        return Scaffold(
          backgroundColor: AppColors.charcoal,
          appBar: state.isObserver
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _teamBlock(
                        state.home.name,
                        state.matchGamesWonHome,
                        Colors.blueAccent,
                        usedTimeout: game.homeTimeoutUsed,
                      ),
                      Expanded(
                        child: Text(
                          "$homeLabel vs $awayLabel",
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _teamBlock(
                        state.away.name,
                        state.matchGamesWonAway,
                        Colors.redAccent,
                        usedTimeout: game.awayTimeoutUsed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (state.isTimeoutActive)
                    _timeoutTimer(state)
                  else if (state.isBreakActive)
                    _breakTimer(state)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 15),
                  _mainScoreboard(state, isHomeServing, isAwayServing),
                  const SizedBox(height: 10),
                  _setScores(game, state.pointsToWin),
                  const SizedBox(height: 10),
                  _matchOverviewFooter(game, state),
                  const SizedBox(height: 20),
                  if (state.isTransitioning &&
                      state.isNextGameReady &&
                      state.nextGamePreview != null)
                    ScoreTransitionOverlay(
                      gameNumber: state.nextGamePreview!.order,
                      totalGames: state.games.length,
                      homeNames: state.home.name,
                      awayNames: state.away.name,
                      homeScore: state.lastGameResult?['homeScore'] ?? 0,
                      awayScore: state.lastGameResult?['awayScore'] ?? 0,
                      setScores:
                          (state.lastGameResult?['setScores'] as List?)
                              ?.map((s) => Map<String, int>.from(s))
                              .toList() ??
                          [],
                      nextHomeNames:
                          state.nextGamePreview!.homePlayers.isNotEmpty
                          ? state.nextGamePreview!.homePlayers
                                .map((p) => p.name)
                                .join(' & ')
                          : state.home.players.map((p) => p.name).join(' & '),
                      nextAwayNames:
                          state.nextGamePreview!.awayPlayers.isNotEmpty
                          ? state.nextGamePreview!.awayPlayers
                                .map((p) => p.name)
                                .join(' & ')
                          : state.away.players.map((p) => p.name).join(' & '),
                      onContinue: () => bloc.add(StartNextGame()),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _breakTimer(MatchControllerState state) {
    final remaining = state.remainingBreakTime ?? Duration.zero;
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
          "${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
          style: GoogleFonts.oswald(
            fontSize: 72,
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _timeoutTimer(MatchControllerState state) {
    final remaining = state.remainingTimeoutTime ?? Duration.zero;
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
          "${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
          style: GoogleFonts.oswald(
            fontSize: 72,
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
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

  Widget _mainScoreboard(
    MatchControllerState state,
    bool isHomeServing,
    bool isAwayServing,
  ) {
    final currentSet = state.currentSet!;
    final game = state.currentGame!;
    bool? homeWonLastSet;

    if (state.isBreakActive && game.sets.isNotEmpty) {
      final lastCompletedSet = game.sets.lastWhere(
        (s) =>
            (s.home >= state.pointsToWin || s.away >= state.pointsToWin) &&
            (s.home - s.away).abs() >= 2,
        orElse: () => SetScore(),
      );
      if (lastCompletedSet.home != lastCompletedSet.away) {
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
            currentSet.home,
            Colors.blueAccent,
            isServing: isHomeServing,
            isWinner: homeWonLastSet == true,
          ),
          _scoreColumn(
            currentSet.away,
            Colors.redAccent,
            isServing: isAwayServing,
            isWinner: homeWonLastSet == false,
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(
    int score,
    Color color, {
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

  Widget _setScores(Game game, int pointsToWin) {
    final completedSets = game.sets.where(
      (s) =>
          (s.home >= pointsToWin || s.away >= pointsToWin) &&
          (s.home - s.away).abs() >= 2,
    );

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

  Widget _matchOverviewFooter(Game game, MatchControllerState state) {
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
            Icons.sports_tennis,
            "Next Serve",
            state.currentServer?.name ?? "--",
          ),
          _footerItem(
            Icons.grid_view_rounded,
            "Game/Set",
            "G${game.order} / S${game.sets.length}",
          ),
        ],
      ),
    );
  }

  Widget _footerItem(IconData icon, String label, String value) {
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
