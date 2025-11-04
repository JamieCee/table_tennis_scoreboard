import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemedDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const ThemedDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0E1A2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF10253E), Color(0xFF07101F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.bebasNeue(
                fontSize: 28,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const Divider(color: Colors.white24, thickness: 1, height: 20),
            const SizedBox(height: 8),
            content,
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ),
      ),
    );
  }
}
