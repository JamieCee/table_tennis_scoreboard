import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class TransitionOverlay extends StatefulWidget {
  final int gameNumber;
  final int totalGames;
  final String homeNames;
  final String awayNames;
  final VoidCallback onStartGame;

  const TransitionOverlay({
    super.key,
    required this.gameNumber,
    required this.totalGames,
    required this.homeNames,
    required this.awayNames,
    required this.onStartGame,
  });

  @override
  State<TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    // Play slide animation
    await _slideCtrl.forward();
    widget.onStartGame();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1.2, 0))
            .animate(
              CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOutCubic),
            ),
        child: Container(
          color: AppColors.charcoal,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game ${widget.gameNumber} of ${widget.totalGames}',
                style: GoogleFonts.orbitron(
                  color: Colors.purple,
                  fontSize: 28,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${widget.homeNames} vs ${widget.awayNames}',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _handleTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.sports_tennis, size: 24),
                label: Text(
                  'Tap to Start Game',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
