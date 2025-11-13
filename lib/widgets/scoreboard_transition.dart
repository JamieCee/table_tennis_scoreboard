import 'package:flutter/material.dart';

class ScoreTransitionOverlay extends StatelessWidget {
  final int gameNumber;
  final int totalGames;
  final String homeNames;
  final String awayNames;
  final int homeScore;
  final int awayScore;
  final List<Map<String, int>> setScores;
  final String? nextHomeNames;
  final String? nextAwayNames;
  final VoidCallback? onContinue;

  const ScoreTransitionOverlay({
    super.key,
    required this.gameNumber,
    required this.totalGames,
    required this.homeNames,
    required this.awayNames,
    required this.homeScore,
    required this.awayScore,
    required this.setScores,
    this.nextHomeNames,
    this.nextAwayNames,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Game $gameNumber of $totalGames',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$homeNames vs $awayNames',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  'Final Score: $homeScore - $awayScore',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: setScores.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final s = entry.value;
                    return Text(
                      'Set $i: ${s['home']} - ${s['away']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
                // 🔹 Divider line with slight glow
                Container(
                  height: 1.5,
                  width: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.yellowAccent.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                if (nextHomeNames != null && nextAwayNames != null)
                  Column(
                    children: [
                      Text(
                        'Up Next: Game ${gameNumber + 1}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$nextHomeNames vs $nextAwayNames',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
              ],
            ),
            if (onContinue != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onContinue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
