import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/match_controller/match_controller_bloc.dart';
import '../models/game.dart';
import '../theme.dart';

class MatchScorecardScreen extends StatelessWidget {
  const MatchScorecardScreen({super.key});

  String _getGameWinnerName(Game game) {
    if (game.homePlayers.isEmpty && game.awayPlayers.isEmpty) return "N/A";
    if (game.setsWonHome > game.setsWonAway) {
      return game.homePlayers.map((p) => p.name).join(' & ');
    } else {
      return game.awayPlayers.map((p) => p.name).join(' & ');
    }
  }

  int _totalHomeGamesWon(List<Game> games) =>
      games.where((g) => g.setsWonHome > g.setsWonAway).length;

  int _totalAwayGamesWon(List<Game> games) =>
      games.where((g) => g.setsWonAway > g.setsWonHome).length;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.charcoal,
          appBar: AppBar(
            title: const Text('Match Scorecard'),
            backgroundColor: AppColors.purple.withValues(alpha: 0.4),
            elevation: 6,
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
                    itemCount: state.games.length,
                    itemBuilder: (context, index) {
                      final game = state.games[index];

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                spacing: 8,
                                runSpacing: 8,
                                children: game.sets.map((set) {
                                  return SizedBox(
                                    width: 50,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.midnightBlue
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.midnightBlue,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${set.home}',
                                            style: GoogleFonts.robotoMono(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
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
                      'Final Score: ${_totalHomeGamesWon(state.games)} - ${_totalAwayGamesWon(state.games)}',
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
      },
    );
  }
}
