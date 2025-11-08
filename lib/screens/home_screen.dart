import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/screens/join_match_screen.dart';
import 'package:table_tennis_scoreboard/screens/team_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2342),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_tennis,
                  color: Colors.orangeAccent,
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
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeamSetupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports, color: Colors.black),
                  label: Text(
                    "Start New Match",
                    style: GoogleFonts.oswald(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Join Existing Match Button ---
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JoinMatchScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link, color: Colors.orangeAccent),
                  label: Text(
                    "Join Existing Match",
                    style: GoogleFonts.oswald(
                      color: Colors.orangeAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.orangeAccent,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//176 261 901 6579
