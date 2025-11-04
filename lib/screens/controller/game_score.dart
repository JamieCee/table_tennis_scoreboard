import 'package:flutter/material.dart';

import '../../controllers/match_controller.dart';
import '../../shared/styled_text.dart';

class GameAndScoreWidget extends StatefulWidget {
  const GameAndScoreWidget({super.key, required this.ctrl});

  final MatchController ctrl;

  @override
  State<GameAndScoreWidget> createState() => _GameAndScoreWidgetState();
}

class _GameAndScoreWidgetState extends State<GameAndScoreWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: StyledHeading(
              'Game ${widget.ctrl.currentGame.order} of ${widget.ctrl.games.length}',
            ),
          ),
          Center(
            child: StyledSubHeading(
              'Match Score: ${widget.ctrl.matchGamesWonHome} - ${widget.ctrl.matchGamesWonAway}',
            ),
          ),
        ],
      ),
    );
  }
}
