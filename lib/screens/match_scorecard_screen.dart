import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/match/match_bloc.dart';
import '../models/game.dart';
import '../theme.dart';

class MatchScorecardScreen extends StatelessWidget {
  const MatchScorecardScreen({super.key});

  (int, int) _calculateGameScore(Game game) {
    int setsWonHome = 0;
    int setsWonAway = 0;

    for (final set in game.sets) {
      // Skip empty "placeholder" sets at the beginning of a game
      if (set.home == 0 && set.away == 0 && game.sets.length > 1) continue;

      if (set.home > set.away) {
        setsWonHome++;
      } else if (set.away > set.home) {
        setsWonAway++;
      }
    }
    return (setsWonHome, setsWonAway);
  }

  String _getGameWinnerName(Game game) {
    final (gameScoreHome, gameScoreAway) = _calculateGameScore(game);

    if (gameScoreHome > gameScoreAway) {
      return game.homePlayers.map((p) => p.name).join(' & ');
    } else if (gameScoreAway > gameScoreHome) {
      return game.awayPlayers.map((p) => p.name).join(' & ');
    } else {
      // If the game is not finished or is a draw (unlikely), show no winner
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final games = state.games;

        int totalHomeGamesWon = 0;
        int totalAwayGamesWon = 0;
        for (final game in games) {
          final (gameScoreHome, gameScoreAway) = _calculateGameScore(game);
          if (gameScoreHome >= state.setsToWin) {
            totalHomeGamesWon++;
          } else if (gameScoreAway >= state.setsToWin) {
            totalAwayGamesWon++;
          }
        }

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
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];

                      final (gameScoreHome, gameScoreAway) =
                          _calculateGameScore(game);

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
                                    '$gameScoreHome - $gameScoreAway',
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
                    child: Builder(
                      builder: (context) {
                        // --- START: MODIFIED LOGIC ---
                        String finalScoreText;
                        if (state.matchType == MatchType.team) {
                          // For TEAM matches, the score is the total games won.
                          finalScoreText =
                              'Final Score: $totalHomeGamesWon - $totalAwayGamesWon';
                        } else {
                          // For SINGLES/HANDICAP, the score is the sets won in the first (and only) game.
                          final (gameScoreHome, gameScoreAway) =
                              _calculateGameScore(games.first);
                          finalScoreText =
                              'Final Score: $gameScoreHome - $gameScoreAway';
                        }
                        // --- END: MODIFIED LOGIC ---

                        return Text(
                          finalScoreText, // Use the determined score string
                          style: GoogleFonts.oswald(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldGreen,
                          ),
                        );
                      },
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
