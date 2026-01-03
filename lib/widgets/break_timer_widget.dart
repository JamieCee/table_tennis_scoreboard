import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';

import '../shared/styled_button.dart';
import '../theme.dart';

class BreakTimerWidget extends StatelessWidget {
  const BreakTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final remaining = state.remainingBreakTime;
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
            border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
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
                onPressed: () =>
                    context.read<MatchControllerBloc>().add(EndBreak()),
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
      },
    );
  }
}
