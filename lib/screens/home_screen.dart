import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_tennis_scoreboard/controllers/auth_controller.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';

import '../controllers/match_controller.dart';
import '../models/team.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authController = AuthController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkForActiveMatch();
    });
  }

  Future<void> _checkForActiveMatch() async {
    if (!mounted) return;

    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return; // <<< KEY GUARD

    final prefs = await SharedPreferences.getInstance();
    final matchId = prefs.getString('activeMatchId');

    if (matchId == null || !mounted) return;

    // Check if match still exists in firestore
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    if (!matchDoc.exists || (matchDoc.data()?['isMatchOver'] ?? false)) {
      await prefs.remove('activeMatchId');
      return;
    }

    // If we're here, there is a match
    showDialog(
      context: context,
      barrierDismissible: false, // An option must be chosen
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resume Match?'),
          content: const Text(
            'You have an unfinished match. Would you like to continue where you left off?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await prefs.remove('activeMatchId');

                // Delete match id from firestore
                await FirebaseFirestore.instance
                    .collection('matches')
                    .doc(matchId)
                    .delete();

                context.go('/home');
                // Navigator.of(context).pop();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                _resumeMatchAsController(matchId, matchDoc.data()!);
              },
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );
  }

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
      return Scaffold(
        backgroundColor: const Color(0xff3E4249),
        appBar: AppBar(
          title: const Text('TT Scoreboard'),
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
                    "TT Scoreboard",
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 56,
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

                  const SizedBox(height: 24),

                  // --- Join Existing Match Button ---
                  OutlinedButton(
                    onPressed: () => context.go('/join-match'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.purple, width: 2),
                      shadowColor: AppColors.purpleAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Join Existing Match",
                      style: GoogleFonts.oswald(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 125,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: AppColors.purpleAccent),
                  padding: EdgeInsets.only(left: 20),
                  child: Text('TT Scoreboard'),
                ),
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  _authController.logout();
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
