import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/match_controller.dart';
import '../shared/styled_button.dart';
import '../theme.dart';

/// --------------------------------------------------------------------
/// BreakTimerWidget
/// --------------------------------------------------------------------
/// A presentational widget that displays the active break countdown.
/// It does NOT manage its own timer logic — it reads all state from
/// the [MatchController].
///
/// The controller should handle:
///   - `isBreakActive`
///   - `remainingBreakTime`
///   - `endBreakEarly()`
///   - `notifyListeners()`
///
/// This widget just listens and shows the data.
/// --------------------------------------------------------------------
class BreakTimerWidget extends StatelessWidget {
  final MatchController ctrl;

  const BreakTimerWidget({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final remaining = ctrl.remainingBreakTime;
    if (remaining == null) return const SizedBox.shrink();

    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Break Time',
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$minutes:$seconds',
              key: ValueKey('$minutes:$seconds'),
              style: GoogleFonts.orbitron(
                color: Colors.purpleAccent,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          StyledIconButton(
            onPressed: ctrl.endBreakEarly,
            icon: const Icon(Icons.timer_off_outlined, color: Colors.black),
            color: Colors.purpleAccent,
            child: const Text(
              'End Break Early',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
