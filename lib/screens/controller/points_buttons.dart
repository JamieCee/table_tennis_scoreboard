import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';

import '../../theme.dart';

class PointsButtons extends StatelessWidget {
  const PointsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final bloc = context.read<MatchControllerBloc>();
        final game = state.currentGame;
        final currentSet = state.currentSet;
        if (game == null || currentSet == null) return const SizedBox.shrink();

        final bool disableButtons =
            state.isBreakActive || state.isTimeoutActive;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: _scoreButtonStyle(AppColors.airForceBlue),
                    onPressed: disableButtons
                        ? null
                        : () => bloc.add(AddPointHome()),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Add +'),
                        SizedBox(height: 2),
                        Text('Home Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: _scoreButtonStyle(Colors.redAccent),
                    onPressed: disableButtons
                        ? null
                        : () => bloc.add(AddPointAway()),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Add +'),
                        SizedBox(height: 2),
                        Text('Away Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: _scoreButtonStyle(
                      Colors.purpleAccent.withOpacity(0.4),
                      isRemove: true,
                    ),
                    onPressed: disableButtons
                        ? null
                        : () => bloc.add(UndoPointHome()),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Subtract'),
                        SizedBox(height: 2),
                        Text('Home Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: _scoreButtonStyle(
                      Colors.purpleAccent.withOpacity(0.4),
                      isRemove: true,
                    ),
                    onPressed: disableButtons
                        ? null
                        : () => bloc.add(UndoPointAway()),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Subtract'),
                        SizedBox(height: 2),
                        Text('Away Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!game.homeTimeoutUsed)
                  Expanded(
                    child: ElevatedButton(
                      style: _scoreButtonStyle(Colors.orangeAccent),
                      onPressed: disableButtons
                          ? null
                          : () => bloc.add(StartTimeout(true)),
                      child: Text(
                        'Home Timeout',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                if (!game.awayTimeoutUsed)
                  Expanded(
                    child: ElevatedButton(
                      style: _scoreButtonStyle(Colors.orangeAccent),
                      onPressed: disableButtons
                          ? null
                          : () => bloc.add(StartTimeout(false)),
                      child: Text(
                        'Away Timeout',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  ButtonStyle _scoreButtonStyle(Color bgColor, {bool isRemove = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isRemove ? 12 : 16),
        side: isRemove
            ? BorderSide(color: AppColors.purple.withOpacity(0.4), width: 1)
            : BorderSide.none,
      ),
      textStyle: GoogleFonts.oswald(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
      elevation: 3,
      shadowColor: bgColor.withOpacity(isRemove ? 0.4 : 0.6),
    );
  }
}
