import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/screens/controller_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
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

  void _startMatch() {
    final home = Team(
      name: _homeNameController.text,
      players: _homePlayers.map((c) => Player(c.text)).toList(),
    );
    final away = Team(
      name: _awayNameController.text,
      players: _awayPlayers.map((c) => Player(c.text)).toList(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MatchController(home: home, away: away),
          child: const ControllerScreen(showDialogOnLoad: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A2342),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_tennis,
                      size: 80,
                      color: Colors.white.withOpacity(0.9),
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
                    Text(
                      "Prepare your teams before battle!",
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Team Inputs ---
              _teamCard(
                label: "Home Team",
                color: Colors.blueAccent,
                controller: _homeNameController,
                players: _homePlayers,
                icon: Icons.home,
              ),
              const SizedBox(height: 24),
              _teamCard(
                label: "Away Team",
                color: Colors.redAccent,
                controller: _awayNameController,
                players: _awayPlayers,
                icon: Icons.flight_takeoff,
              ),

              const SizedBox(height: 36),

              // --- Start Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  "Start Match",
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.greenAccent.withOpacity(0.6),
                ),
                onPressed: _startMatch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamCard({
    required String label,
    required Color color,
    required IconData icon,
    required TextEditingController controller,
    required List<TextEditingController> players,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
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
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Team Name', color),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            TextField(
              controller: players[i],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Player ${i + 1}',
                color.withOpacity(0.9),
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
      labelStyle: TextStyle(color: color.withOpacity(0.9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
