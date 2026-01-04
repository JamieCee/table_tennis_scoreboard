import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/match/match_bloc.dart';
import '../shared/styled_button.dart';
import '../theme.dart';

/// --------------------------------------------------------------------
/// TimeoutTimerWidget
/// --------------------------------------------------------------------
/// Shows the active timeout countdown. Uses BLoC instead of controller.
/// --------------------------------------------------------------------
class TimeoutTimerWidget extends StatelessWidget {
  const TimeoutTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final timeLeft = state.remainingTimeoutTime;
        if (timeLeft == null) return const SizedBox.shrink();

        final minutes = timeLeft.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        final seconds = timeLeft.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                state.timeoutCalledByHome ? "Home Timeout" : "Away Timeout",
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(height: 12),
              StyledIconButton(
                onPressed: () =>
                    context.read<MatchBloc>().add(EndTimeoutEarly()),
                icon: const Icon(Icons.timer_off_outlined, color: Colors.black),
                color: Colors.purpleAccent,
                child: const Text(
                  'End Timeout Early',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
