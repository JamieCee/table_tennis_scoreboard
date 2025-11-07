import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/match_controller.dart';
import '../shared/styled_button.dart';
import '../theme.dart';

class TimeoutTimerWidget extends StatelessWidget {
  final MatchController ctrl;
  const TimeoutTimerWidget({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final timeLeft = ctrl.remainingTimeoutTime;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.midnightBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            ctrl.timeoutCalledByHome ? "Home Timeout" : "Away Timeout",
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${timeLeft?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeLeft?.inSeconds.remainder(60).toString().padLeft(2, '0')}',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 12),
          StyledIconButton(
            onPressed: ctrl.endTimeoutEarly,
            icon: const Icon(Icons.timer_off_outlined, color: Colors.black),
            color: Colors.orangeAccent,
            child: const Text(
              'End Timeout Early',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
