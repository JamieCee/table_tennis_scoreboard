import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/theme.dart';

import '../../bloc/match/match_bloc.dart';

class PointsButtons extends StatelessWidget {
  const PointsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final bloc = context.read<MatchBloc>();
        final disable =
            state.isBreakActive ||
            state.isTimeoutActive ||
            !state.isGameEditable;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: disable ? null : () => bloc.add(AddPointHome()),
                    style: _scoreButtonStyle(AppColors.airForceBlue),
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
                    onPressed: disable ? null : () => bloc.add(AddPointAway()),
                    style: _scoreButtonStyle(Colors.redAccent),
                    child: const Column(
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
                    onPressed: disable ? null : () => bloc.add(UndoPointHome()),
                    style: _scoreButtonStyle(
                      AppColors.purpleAccent.withValues(alpha: 0.4),
                      isRemove: true,
                    ),
                    child: const Column(
                      children: [
                        Text('Undo -'),
                        SizedBox(height: 2),
                        Text('Home Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: disable ? null : () => bloc.add(UndoPointAway()),
                    style: _scoreButtonStyle(
                      AppColors.purpleAccent.withValues(alpha: 0.4),
                      isRemove: true,
                    ),
                    child: const Column(
                      children: [
                        Text('Undo -'),
                        SizedBox(height: 2),
                        Text('Away Point', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              height: 2,
              width: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.purpleAccent.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Visibility(
                    visible: !state.currentGame!.homeTimeoutUsed,
                    child: ElevatedButton(
                      style: _scoreButtonStyle(Colors.orangeAccent),
                      onPressed: disable
                          ? null
                          : () => bloc.add(StartTimeout(isHome: true)),
                      child: Text(
                        'Home Timeout',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Visibility(
                    visible: !state.currentGame!.awayTimeoutUsed,
                    child: ElevatedButton(
                      style: _scoreButtonStyle(Colors.orangeAccent),
                      onPressed: disable
                          ? null
                          : () => bloc.add(StartTimeout(isHome: false)),
                      child: Text(
                        'Away Timeout',
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
}

ButtonStyle _scoreButtonStyle(Color bgColor, {bool isRemove = false}) {
  return ElevatedButton.styleFrom(
    backgroundColor: bgColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isRemove ? 12 : 16),
      side: isRemove
          ? BorderSide(color: AppColors.purple.withValues(alpha: 0.4), width: 1)
          : BorderSide.none,
    ),
    textStyle: GoogleFonts.oswald(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
    ),
    elevation: 3,
    shadowColor: bgColor.withValues(alpha: isRemove ? 0.4 : 0.6),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.1);
      }
      return null;
    }),
  );
}
