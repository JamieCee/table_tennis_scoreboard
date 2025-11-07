import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/match_controller.dart';
import '../shared/styled_button.dart';
import '../theme.dart';

class TimeoutTimerWidget extends StatefulWidget {
  final MatchController ctrl;
  const TimeoutTimerWidget({super.key, required this.ctrl});

  @override
  State<TimeoutTimerWidget> createState() => _TimeoutTimerWidgetState();
}

class _TimeoutTimerWidgetState extends State<TimeoutTimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start ticking the timeout countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final ctrl = widget.ctrl;

      if (ctrl.remainingTimeoutTime == null ||
          ctrl.remainingTimeoutTime!.inSeconds <= 0) {
        ctrl.endTimeout();
        _timer?.cancel();
      } else {
        ctrl.remainingTimeoutTime =
            ctrl.remainingTimeoutTime! - const Duration(seconds: 1);
        ctrl.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
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
