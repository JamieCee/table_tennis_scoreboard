import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_tennis_scoreboard/controllers/auth_controller.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  MatchType _matchType = MatchType.team;
  int _setsToWin = 3; // Number of sets to win by
  final _authController = AuthController();

  int _handicapPlayerIndex = 0;
  double _handicapPoints = 0;

  final _homeNameController = TextEditingController(text: 'Home Team');
  final _awayNameController = TextEditingController(text: 'Away Team');

  final _homePlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'H${i + 1}'),
  ); // 3 players in a home team
  final _awayPlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'A${i + 1}'),
  ); // 3 players in the away team

  // Generate a 6-character alphanumeric match ID as a join code
  String _generateMatchId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void _startMatch() async {
    // List the collection of home players or the singles player
    final homePlayers = _matchType == MatchType.team
        ? _homePlayers.map((c) => Player(c.text)).toList()
        : [_homePlayers.first].map((c) => Player(c.text)).toList();

    // List the collection of away players or the singles player
    final awayPlayers = _matchType == MatchType.team
        ? _awayPlayers.map((c) => Player(c.text)).toList()
        : [_awayPlayers.first].map((c) => Player(c.text)).toList();

    // If its a team game, show team name, else show the singles player
    final home = Team(
      name: _matchType == MatchType.team
          ? _homeNameController.text
          : homePlayers.first.name,
      players: homePlayers,
    );

    // If its a team game, show team name, else show the singles player
    final away = Team(
      name: _matchType == MatchType.team
          ? _awayNameController.text
          : awayPlayers.first.name,
      players: awayPlayers,
    );

    final matchId = _generateMatchId();

    // Create new match controller
    final controller = MatchController(
      home: home,
      away: away,
      matchId: matchId,
      matchType: _matchType,
      setsToWin: _setsToWin,
      handicapDetails: _matchType == MatchType.handicap
          ? {
              'playerIndex': _handicapPlayerIndex,
              'points': _handicapPoints.toInt(),
            }
          : null,
    );

    // Create Firestore document
    await controller.createMatchInFirestore();

    // Save active match ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeMatchId', matchId);

    // context.pushReplacement('/controller', extra: controller);
    context.go('/controller', extra: controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3E4249),
      // appBar: AppBar(
      //   backgroundColor: AppColors.primaryBackground,
      //   leading: Builder(
      //     builder: (context) {
      //       return IconButton(
      //         icon: const Icon(Icons.menu),
      //         onPressed: () {
      //           Scaffold.of(context).openDrawer();
      //         },
      //       );
      //     },
      //   ),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 80,
                      color: Colors.purpleAccent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Match Setup",
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 48,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildMatchTypeSelector(),
              const SizedBox(height: 16),
              if (_matchType == MatchType.singles) _buildSetsToWinSelector(),
              if (_matchType == MatchType.handicap) _buildHandicapSelector(),
              const SizedBox(height: 24),
              _teamCard(
                label: _matchType == MatchType.team ? "Home Team" : "Player 1",
                color: Colors.blueAccent,
                controller: _homeNameController,
                players: _homePlayers,
                playerCount: _matchType == MatchType.team ? 3 : 1,
              ),
              const SizedBox(height: 24),
              _teamCard(
                label: _matchType == MatchType.team ? "Away Team" : "Player 2",
                color: Colors.redAccent,
                controller: _awayNameController,
                players: _awayPlayers,
                playerCount: _matchType == MatchType.team ? 3 : 1,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.purple.withValues(alpha: 0.6),
                ),
                onPressed: _startMatch,
                child: Text(
                  "Start Match",
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
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
              leading: Icon(Icons.house),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
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

  // Match type selector (singles or team)
  Widget _buildMatchTypeSelector() {
    return SegmentedButton<MatchType>(
      segments: const [
        ButtonSegment(value: MatchType.team, label: Text('Team')),
        ButtonSegment(value: MatchType.singles, label: Text('Singles')),
        ButtonSegment(value: MatchType.handicap, label: Text('Handicap')),
      ],
      selected: {_matchType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _matchType = newSelection.first;

          // --- Add/Modify this logic block ---
          if (_matchType == MatchType.singles) {
            _setsToWin = 2; // Default to 'Best of 3'
          } else if (_matchType == MatchType.handicap) {
            _setsToWin = 2; // Default handicap to 'Best of 3' as well
          } else {
            // This handles the 'Team' case
            _setsToWin = 3; // Team games are best of 5 sets
          }
          // --- End of logic block ---

          // This handles resetting handicap points if you switch away from it
          if (_matchType != MatchType.handicap) {
            _handicapPoints = 0;
          }
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        selectedBackgroundColor: AppColors.purpleAccent.withValues(alpha: 0.4),
        selectedForegroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildSetsToWinSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 2, label: Text('Best of 3')),
        ButtonSegment(value: 3, label: Text('Best of 5')),
        ButtonSegment(value: 4, label: Text('Best of 7')),
      ],
      selected: {_setsToWin},
      onSelectionChanged: (newSelection) {
        setState(() {
          _setsToWin = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        selectedBackgroundColor: AppColors.purpleAccent.withValues(alpha: 0.4),
        selectedForegroundColor: AppColors.white,
      ),
    );
  }

  Widget _teamCard({
    required String label,
    required Color color,
    required TextEditingController controller,
    required List<TextEditingController> players,
    required int playerCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 1), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.oswald(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          if (_matchType == MatchType.team) ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Team Name', AppColors.white),
            ),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < playerCount; i++) ...[
            TextField(
              controller: players[i],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                _matchType == MatchType.team
                    ? 'Player ${i + 1}'
                    : 'Player Name',
                AppColors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildHandicapSelector() {
    String homePlayerName = _homePlayers.first.text.isNotEmpty
        ? _homePlayers.first.text
        : 'Player 1';
    String awayPlayerName = _awayPlayers.first.text.isNotEmpty
        ? _awayPlayers.first.text
        : 'Player 2';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purpleAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Handicap Setup",
            style: GoogleFonts.oswald(
              color: Colors.purpleAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(homePlayerName)),
              ButtonSegment(value: 1, label: Text(awayPlayerName)),
            ],
            selected: {_handicapPlayerIndex},
            onSelectionChanged: (newSelection) {
              setState(() {
                _handicapPlayerIndex = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.primaryBackground.withValues(
                alpha: 0.5,
              ),
              foregroundColor: Colors.white,
              selectedBackgroundColor: AppColors.purpleAccent.withValues(
                alpha: 0.4,
              ),
              selectedForegroundColor: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Starting Points Slider
          Text(
            "Starting Points: ${_handicapPoints.toInt()}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Slider(
            value: _handicapPoints,
            min: 0,
            max: 20, // Cannot start at 21 or more
            divisions: 20,
            label: _handicapPoints.toInt().toString(),
            activeColor: Colors.white,
            inactiveColor: Colors.purpleAccent.withValues(alpha: 0.3),
            onChanged: (newValue) {
              setState(() {
                _handicapPoints = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, Color color) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: color.withValues(alpha: 0.9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }
}
