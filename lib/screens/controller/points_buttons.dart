import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/match_controller.dart';
import '../../theme.dart';

class PointsButtons extends StatefulWidget {
  const PointsButtons({super.key, required this.ctrl});

  final MatchController ctrl;

  @override
  State<PointsButtons> createState() => _PointsButtonsState();
}

class _PointsButtonsState extends State<PointsButtons> {
  @override
  Widget build(BuildContext context) {
    final bool disableButtons =
        widget.ctrl.isBreakActive ||
        !widget.ctrl.isGameEditable ||
        widget.ctrl.isTimeoutActive;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ElevatedButton(
                style: _scoreButtonStyle(AppColors.airForceBlue),
                onPressed: disableButtons ? null : widget.ctrl.addPointHome,
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
                onPressed: disableButtons ? null : widget.ctrl.addPointAway,
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
                  Colors.deepPurpleAccent.shade700.withValues(alpha: 0.4),
                  isRemove: true,
                ),
                onPressed: disableButtons ? null : widget.ctrl.undoPointHome,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Subtract -'),
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
                  Colors.deepPurpleAccent.shade700.withValues(alpha: 0.4),
                  isRemove: true,
                ),
                onPressed: disableButtons ? null : widget.ctrl.undoPointAway,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Subtract -'),
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
              child: Visibility(
                visible: !widget.ctrl.currentGame.homeTimeoutUsed,
                child: ElevatedButton(
                  style: _scoreButtonStyle(Colors.orangeAccent),
                  onPressed: disableButtons || widget.ctrl.isTimeoutActive
                      ? null
                      : () => widget.ctrl.startTimeout(isHome: true),
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
                visible: !widget.ctrl.currentGame.awayTimeoutUsed,
                child: ElevatedButton(
                  style: _scoreButtonStyle(Colors.orangeAccent),
                  onPressed: disableButtons || widget.ctrl.isTimeoutActive
                      ? null
                      : () => widget.ctrl.startTimeout(isHome: false),
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
  }

  ButtonStyle _scoreButtonStyle(Color bgColor, {bool isRemove = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isRemove ? 12 : 16),
        side: isRemove
            ? BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1)
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
}
