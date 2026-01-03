import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match_check/match_check_bloc.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

import '../controllers/match_controller.dart';
import '../models/team.dart';
import '../services/match_state_manager.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _resumeMatchAsController(
    String matchId,
    Map<String, dynamic> matchData,
  ) {
    try {
      // Take data from the document (database)
      final homeTeamData = matchData['home'];
      final awayTeamData = matchData['away'];
      final matchTypeString = matchData['matchType'] as String?;
      final setsToWin = matchData['setsToWin'] as int?;
      final handicapDetails = matchData['handicapDetails'] as Map<String, int>?;

      final homeTeam = Team.fromJson(homeTeamData);
      final awayTeam = Team.fromJson(awayTeamData);

      // Re-create team objects from the data
      MatchType matchType;
      if (matchTypeString == 'MatchType.singles') {
        matchType = MatchType.singles;
      } else if (matchTypeString == 'MatchType.handicap') {
        matchType = MatchType.handicap;
      } else {
        matchType = MatchType.team;
      }

      // Create match controller
      final controller = MatchController.resume(
        home: homeTeam,
        away: awayTeam,
        matchId: matchId,
        isObserver: false,
        matchType: matchType,
        setsToWin: setsToWin ?? 3,
        handicapDetails: handicapDetails,
        resumeData: matchData,
        matchStateManager: context.read<MatchStateManager>(),
      );

      context.go('/controller', extra: controller);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error resuming match: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const JoinMatchScreen();
    } else {
      return BlocProvider(
        create: (context) => MatchCheckBloc()..add(CheckForActiveMatch()),
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
              title: Text(''),
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
                              color: AppColors.purple.withValues(
                                alpha: 0.8,
                              ), // shadow color
                              spreadRadius: 0,
                              blurRadius: 6, // softness of shadow
                              offset: Offset(0, 8), // vertical offset
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
        // Use a different context name
        return AlertDialog(
          title: const Text('Resume Match?'),
          content: const Text(
            'You have an unfinished match. Would you like to continue where you left off?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // 3. Dispatch an event to the Bloc
                matchCheckBloc.add(DiscardActiveMatch(matchId: matchId));
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close dialog before navigating
                _resumeMatchAsController(matchId, matchData);
              },
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
  }
}
