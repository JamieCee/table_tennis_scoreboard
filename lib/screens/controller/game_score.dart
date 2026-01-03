import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';

import '../../shared/styled_text.dart';

class GameAndScoreWidget extends StatelessWidget {
  const GameAndScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final game = state.currentGame;
        if (game == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: StyledHeading('Game ${game.order} of ${state.games.length}'),
          ),
        );
      },
    );
  }
}
