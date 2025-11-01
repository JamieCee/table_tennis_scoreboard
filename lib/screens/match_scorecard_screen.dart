import 'package:flutter/material.dart';

import '../controllers/match_controller.dart';
import '../models/game.dart';

class MatchScorecardScreen extends StatelessWidget {
  final MatchController ctrl;

  const MatchScorecardScreen({super.key, required this.ctrl});

  // <--- Add this here
  String _getGameWinnerName(Game game) {
    if (game.setsWonHome > game.setsWonAway) {
      return game.homePlayers.map((p) => p.name).join(' & ');
    } else {
      return game.awayPlayers.map((p) => p.name).join(' & ');
    }
  }

  int _totalHomeGamesWon() {
    return ctrl.games.where((g) => g.setsWonHome > g.setsWonAway).length;
  }

  int _totalAwayGamesWon() {
    return ctrl.games.where((g) => g.setsWonAway > g.setsWonHome).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Scorecard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.games.length,
                itemBuilder: (context, index) {
                  final game = ctrl.games[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game ${game.order} | ${game.setsWonHome}-${game.setsWonAway} | Winner: ${_getGameWinnerName(game)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            children: game.sets.map((set) {
                              return Column(
                                children: [
                                  Text(
                                    '${set.home}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('${set.away}'),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Text(
                  'Final Score | ${_totalHomeGamesWon()} - ${_totalAwayGamesWon()}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
