import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match/match_bloc.dart';
import 'package:table_tennis_scoreboard/bloc/match_check/match_check_bloc.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

import '../models/team.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Resume a match by creating a MatchBloc with the saved state
  void _resumeMatchAsController(
    String matchId,
    Map<String, dynamic> matchData,
  ) {
    try {
      // --- Teams ---
      final homeTeam = Team.fromJson(matchData['home']);
      final awayTeam = Team.fromJson(matchData['away']);

      // --- Match Type ---
      final matchTypeString = matchData['matchType'] as String?;
      final setsToWin = matchData['setsToWin'] as int? ?? 3;
      final handicapDetails = matchData['handicapDetails'] as Map<String, int>?;

      MatchType matchType;
      if (matchTypeString == 'MatchType.singles') {
        matchType = MatchType.singles;
      } else if (matchTypeString == 'MatchType.handicap') {
        matchType = MatchType.handicap;
      } else {
        matchType = MatchType.team;
      }

      // --- Create the bloc properly with all required parameters ---
      final matchBloc = MatchBloc(
        matchId: matchId,
        home: homeTeam,
        away: awayTeam,
        isObserver: false,
        matchType: matchType,
        setsToWin: setsToWin,
        handicapDetails: handicapDetails,
        matchStateManager: context.read<MatchStateManager>(),
      );

      // --- Dispatch resume event to load previous match data ---
      matchBloc.add(MatchResumed(matchData));

      // --- Navigate with the bloc ---
      context.go('/controller', extra: matchBloc);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error resuming match: $e'),
        ),
      );
    }
  }

  /// Show a dialog prompting the user to resume or discard an active match
  void _showResumeMatchDialog(
    BuildContext context,
    String matchId,
    Map<String, dynamic> matchData,
  ) {
    final matchCheckBloc = BlocProvider.of<MatchCheckBloc>(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Resume Match?'),
          content: const Text(
            'You have an unfinished match. Would you like to continue where you left off?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                matchCheckBloc.add(DiscardActiveMatch(matchId: matchId));
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                _resumeMatchAsController(matchId, matchData);
              },
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const JoinMatchScreen();
    } else {
      return BlocProvider(
        create: (_) => MatchCheckBloc()..add(CheckForActiveMatch()),
        child: BlocListener<MatchCheckBloc, MatchCheckState>(
          listener: (context, state) {
            if (state is ActiveMatchFound) {
              _showResumeMatchDialog(context, state.matchId, state.matchData);
            } else if (state is MatchCheckError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(state.message),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xff3E4249),
            appBar: AppBar(
              title: const Text(''),
              backgroundColor: AppColors.primaryBackground,
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_tennis,
                        color: AppColors.purpleAccent,
                        size: 100,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "Digital Scoreboard",
                        style: GoogleFonts.bebasNeue(
                          color: Colors.white,
                          fontSize: 40,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // --- Start New Match Button ---
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.8),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/team-setup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purpleAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Start New Match",
                            style: GoogleFonts.oswald(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            drawer: const AppDrawer(),
          ),
        ),
      );
    }
  }
}
