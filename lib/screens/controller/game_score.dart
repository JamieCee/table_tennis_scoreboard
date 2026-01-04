import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/match/match_bloc.dart';

class GameAndScoreWidget extends StatelessWidget {
  const GameAndScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final game = state.currentGame;

        // Null-safe: if currentGame is null, show placeholder
        if (game == null) {
          return const Center(
            child: Text(
              'No active game',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Find the game index (1-based for display)
        final gameIndex =
            state.games.indexOf(game) + 1; // indexOf returns 0-based

        return Center(
          child: Text(
            'Game $gameIndex of ${state.games.length}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
