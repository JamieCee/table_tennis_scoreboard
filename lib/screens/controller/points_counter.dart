import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';

import '../../theme.dart';

class PointsCounter extends StatelessWidget {
  const PointsCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final game = state.currentGame;
        final currentSet = state.currentSet;
        if (game == null || currentSet == null) return const SizedBox.shrink();

        String homeLabel = game.homePlayers.isNotEmpty
            ? game.homePlayers.map((p) => p.name).join(" & ")
            : state.home.players.map((p) => p.name).join(" & ");

        String awayLabel = game.awayPlayers.isNotEmpty
            ? game.awayPlayers.map((p) => p.name).join(" & ")
            : state.away.players.map((p) => p.name).join(" & ");

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
                  homeLabel,
                  currentSet.home,
                  game.setsWonHome,
                  game.homeTimeoutUsed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scoreColumn(
                  awayLabel,
                  currentSet.away,
                  game.setsWonAway,
                  game.awayTimeoutUsed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scoreColumn(String label, int points, int sets, bool usedTimeout) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text('Points: $points', style: const TextStyle(fontSize: 22)),
        Text(
          'Sets: $sets',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        if (usedTimeout)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.timer, color: AppColors.white, size: 18),
          ),
      ],
    );
  }
}
