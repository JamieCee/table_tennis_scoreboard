import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  MatchType _matchType = MatchType.team;
  int _setsToWin = 3;

  final _homeNameController = TextEditingController(text: 'Home Team');
  final _awayNameController = TextEditingController(text: 'Away Team');

  final _homePlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'H${i + 1}'),
  );
  final _awayPlayers = List.generate(
    3,
    (i) => TextEditingController(text: 'A${i + 1}'),
  );

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
    final homePlayers = _matchType == MatchType.team
        ? _homePlayers.map((c) => Player(c.text)).toList()
        : [_homePlayers.first].map((c) => Player(c.text)).toList();

    final awayPlayers = _matchType == MatchType.team
        ? _awayPlayers.map((c) => Player(c.text)).toList()
        : [_awayPlayers.first].map((c) => Player(c.text)).toList();

    final home = Team(
      name: _matchType == MatchType.team
          ? _homeNameController.text
          : homePlayers.first.name,
      players: homePlayers,
    );
    final away = Team(
      name: _matchType == MatchType.team
          ? _awayNameController.text
          : awayPlayers.first.name,
      players: awayPlayers,
    );

    final matchId = _generateMatchId();
    final controller = MatchController(
      home: home,
      away: away,
      matchId: matchId,
      matchType: _matchType,
      setsToWin: _setsToWin,
    );

    // Create Firestore document
    await controller.createMatchInFirestore();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: const ControllerScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff5e646e).withValues(alpha: 0.5),
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
              if (_matchType == MatchType.singles) ...[
                const SizedBox(height: 16),
                _buildSetsToWinSelector(),
              ],
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
    );
  }

  Widget _buildMatchTypeSelector() {
    return SegmentedButton<MatchType>(
      segments: const [
        ButtonSegment(value: MatchType.team, label: Text('Team')),
        ButtonSegment(value: MatchType.singles, label: Text('Singles')),
      ],
      selected: {_matchType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _matchType = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        selectedForegroundColor: AppColors.purpleAccent,
      ),
    );
  }

  Widget _buildSetsToWinSelector() {
    return SegmentedButton<int>(
      segments: const [
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
        selectedForegroundColor: AppColors.purpleAccent,
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
        border: Border.all(color: color.withValues(alpha: 1), width: 1.5),
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
