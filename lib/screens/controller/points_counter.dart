import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/match/match_bloc.dart';
import '../../theme.dart';

class PointsCounter extends StatelessWidget {
  const PointsCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final game = state.currentGame;
        final setScore = state.currentSet;

        // If either is null, show nothing
        if (game == null || setScore == null) return const SizedBox.shrink();

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
                  state.matchGamesWonHome,
                  game.homeTimeoutUsed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scoreColumn(
                  game.awayPlayers.map((p) => p.name).join(' & '),
                  setScore.away,
                  state.matchGamesWonAway,
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
