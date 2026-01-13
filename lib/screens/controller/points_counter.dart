import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_tennis_scoreboard/models/game.dart';

import '../../bloc/match/match_bloc.dart';
import '../../theme.dart';

class PointsCounter extends StatelessWidget {
  const PointsCounter({super.key});

  // Helper function to calculate the set score for the current game
  (int, int) _calculateCurrentGameSetScore(Game currentGame) {
    int setsWonHome = 0;
    int setsWonAway = 0;

    // Iterate over the sets of ONLY the current game to count victories
    for (final set in currentGame.sets) {
      // Don't include the active, unfinished set in the tally.
      // The last set is the current one. A set isn't won at 0-0.
      if (set == currentGame.sets.last && (set.home < 11 && set.away < 11))
        continue;

      if (set.home > set.away) {
        setsWonHome++;
      } else if (set.away > set.home) {
        setsWonAway++;
      }
    }
    return (setsWonHome, setsWonAway);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final game = state.currentGame;
        final setScore = state.currentSet;

        // If either is null, show nothing
        if (game == null || setScore == null) return const SizedBox.shrink();

        final (setsWonHome, setsWonAway) = _calculateCurrentGameSetScore(game);

        return Container(
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
                  game.homePlayers.map((p) => p.name).join(' & '),
                  setScore.home,
                  setsWonHome,
                  game.homeTimeoutUsed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scoreColumn(
                  game.awayPlayers.map((p) => p.name).join(' & '),
                  setScore.away,
                  setsWonAway,
                  game.awayTimeoutUsed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scoreColumn(String name, int points, int sets, bool timeoutUsed) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        Text('Points: $points', style: const TextStyle(fontSize: 22)),
        Text(
          'Sets: $sets',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        if (timeoutUsed)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.timer, size: 18, color: AppColors.white),
          ),
      ],
    );
  }
}
