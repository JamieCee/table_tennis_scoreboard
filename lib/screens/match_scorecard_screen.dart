// import 'package:flutter/material.dart';
//
// import '../controllers/match_controller.dart';
// import '../models/game.dart';
//
// class MatchScorecardScreen extends StatelessWidget {
//   final MatchController ctrl;
//
//   const MatchScorecardScreen({super.key, required this.ctrl});
//
//   // <--- Add this here
//   String _getGameWinnerName(Game game) {
//     if (game.setsWonHome > game.setsWonAway) {
//       return game.homePlayers.map((p) => p.name).join(' & ');
//     } else {
//       return game.awayPlayers.map((p) => p.name).join(' & ');
//     }
//   }
//
//   int _totalHomeGamesWon() {
//     return ctrl.games.where((g) => g.setsWonHome > g.setsWonAway).length;
//   }
//
//   int _totalAwayGamesWon() {
//     return ctrl.games.where((g) => g.setsWonAway > g.setsWonHome).length;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Match Scorecard')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 itemCount: ctrl.games.length,
//                 itemBuilder: (context, index) {
//                   final game = ctrl.games[index];
//
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Game ${game.order} | ${game.setsWonHome}-${game.setsWonAway} | Winner: ${_getGameWinnerName(game)}',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Wrap(
//                             spacing: 12,
//                             children: game.sets.map((set) {
//                               return Column(
//                                 children: [
//                                   Text(
//                                     '${set.home}',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   Text('${set.away}'),
//                                 ],
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 6),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 10, top: 10),
//                 child: Text(
//                   'Final Score | ${_totalHomeGamesWon()} - ${_totalAwayGamesWon()}',
//                   style: const TextStyle(fontSize: 18),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/match_controller.dart';
import '../models/game.dart';
import '../theme.dart';

class MatchScorecardScreen extends StatelessWidget {
  final MatchController ctrl;

  const MatchScorecardScreen({super.key, required this.ctrl});

  String _getGameWinnerName(Game game) {
    if (game.setsWonHome > game.setsWonAway) {
      return game.homePlayers.map((p) => p.name).join(' & ');
    } else {
      return game.awayPlayers.map((p) => p.name).join(' & ');
    }
  }

  int _totalHomeGamesWon() =>
      ctrl.games.where((g) => g.setsWonHome > g.setsWonAway).length;

  int _totalAwayGamesWon() =>
      ctrl.games.where((g) => g.setsWonAway > g.setsWonHome).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text('Match Scorecard'),
        backgroundColor: AppColors.midnightBlue,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.timberWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.games.length,
                itemBuilder: (context, index) {
                  final game = ctrl.games[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.steelGray,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Game ${game.order}',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.timberWhite,
                                ),
                              ),
                              Text(
                                '${game.setsWonHome} - ${game.setsWonAway}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Winner: ${_getGameWinnerName(game)}',
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Sets Row
                          Wrap(
                            spacing: 12,
                            children: game.sets.map((set) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.midnightBlue.withOpacity(
                                    0.7,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${set.home}',
                                      style: GoogleFonts.robotoMono(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    Text(
                                      '${set.away}',
                                      style: GoogleFonts.robotoMono(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Final Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.midnightBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Final Score: ${_totalHomeGamesWon()} - ${_totalAwayGamesWon()}',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
