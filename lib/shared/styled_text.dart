import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StyledButtonText extends StatelessWidget {
  const StyledButtonText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.oswald(
        textStyle: Theme.of(context).textTheme.bodyLarge,
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.oswald(
        textStyle: Theme.of(context).textTheme.headlineMedium,
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class StyledSubHeading extends StatelessWidget {
  const StyledSubHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.oswald(
        textStyle: Theme.of(context).textTheme.headlineSmall,
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
