import 'package:flutter/material.dart';

import '../../controllers/match_controller.dart';

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
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, int points, int sets) {
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
      ],
    );
  }
}
