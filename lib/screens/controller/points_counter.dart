import 'package:flutter/material.dart';

import '../../controllers/match_controller.dart';
import '../../theme.dart';

class PointsCounter extends StatefulWidget {
  const PointsCounter({super.key, required this.ctrl});

  final MatchController ctrl;

  @override
  State<PointsCounter> createState() => _PointsCounterState();
}

class _PointsCounterState extends State<PointsCounter> {
  @override
  Widget build(BuildContext context) {
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
              widget.ctrl.currentGame.homePlayers
                  .map((p) => p.name)
                  .join(" & "),
              widget.ctrl.currentSet.home,
              widget.ctrl.currentGame.setsWonHome,
              widget.ctrl.currentGame.homeTimeoutUsed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _scoreColumn(
              widget.ctrl.currentGame.awayPlayers
                  .map((p) => p.name)
                  .join(" & "),
              widget.ctrl.currentSet.away,
              widget.ctrl.currentGame.setsWonAway,
              widget.ctrl.currentGame.awayTimeoutUsed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, int points, int sets, bool usedTimeout) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        Text('Points: $points', style: const TextStyle(fontSize: 22)),
        Text(
          'Sets: $sets',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        if (usedTimeout)
          Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.timer, color: AppColors.white, size: 18),
          ),
      ],
    );
  }
}
