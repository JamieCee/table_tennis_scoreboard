import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamScoreDisplay extends StatelessWidget {
  final int homeScore;
  final int awayScore;

  const TeamScoreDisplay({
    super.key,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _teamColumn("Home", homeScore),
        const SizedBox(width: 24),
        const Text("|", style: TextStyle(fontSize: 32, color: Colors.white54)),
        const SizedBox(width: 24),
        _teamColumn("Away", awayScore),
      ],
    );
  }

  Widget _teamColumn(String label, int score) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 18,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          score.toString(),
          style: GoogleFonts.oswald(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
