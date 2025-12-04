import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/services/match_firestore_service.dart';

import '../models/player.dart';
import '../models/team.dart';
import '../theme.dart';

class JoinMatchScreen extends StatefulWidget {
  final bool isWebObserver;

  const JoinMatchScreen({super.key, this.isWebObserver = false});

  @override
  State<JoinMatchScreen> createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends State<JoinMatchScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _joinMatch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final matchId = _codeController.text.trim();
    if (matchId.isEmpty) {
      setState(() {
        _error = "Please enter a game code.";
        _loading = false;
      });
      return;
    }

    try {
      final doc = await MatchFirestoreService(matchId).streamMatch().first;
      if (!doc.exists) {
        setState(() {
          _error = "Match not found.";
          _loading = false;
        });
        return;
      }

      final data = doc.data()!;
      final homeTeam = data['home'];
      final awayTeam = data['away'];
      final matchTypeString = data['matchType'] as String?;
      final setsToWin = data['setsToWin'] as int?;

      MatchType matchType;
      if (matchTypeString == 'MatchType.singles') {
        matchType = MatchType.singles;
      } else if (matchTypeString == 'MatchType.handicap') {
        matchType = MatchType.handicap;
      } else {
        // Default to team if the string is anything else or null
        matchType = MatchType.team;
      }

      // Create controller in observer mode
      final controller = MatchController(
        home: Team(
          name: homeTeam['name'],
          players: (homeTeam['players'] as List).map((p) => Player(p)).toList(),
        ),
        away: Team(
          name: awayTeam['name'],
          players: (awayTeam['players'] as List).map((p) => Player(p)).toList(),
        ),
        matchId: matchId,
        isObserver: true, // OBSERVER MODE
        matchType: matchType,
        setsToWin: setsToWin ?? 3, // Default to 3 if not present
      );

      // Push ControllerScreen and remove all previous routes
      context.pushReplacement('/controller', extra: controller);

      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ChangeNotifierProvider.value(
      //       value: controller,
      //       child: const ScoreboardDisplayScreen(),
      //     ),
      //   ),
      //   (_) => false,
      // );
    } catch (e) {
      setState(() {
        _error = "Failed to join match.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      // --- START: MODIFICATION FOR STEP 3 ---
      appBar: AppBar(
        // This line is the key. It shows the back button on mobile but hides it on web.
        automaticallyImplyLeading: !widget.isWebObserver,
        // Make the AppBar transparent to keep your original design
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Optional: Give it a title for context
        title: const Text("Join as Observer"),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      // --- END: MODIFICATION FOR STEP 3 ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: "Enter game code",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent.shade200),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _joinMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(
                        "Join Match",
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
