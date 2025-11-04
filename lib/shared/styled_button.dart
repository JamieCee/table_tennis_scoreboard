import 'package:flutter/material.dart';
import 'package:table_tennis_scoreboard/theme.dart';

class StyledButton extends StatelessWidget {
  const StyledButton({super.key, required this.onPressed, required this.child});

  final Function()? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
        child: child,
      ),
    );
  }
}

class StyledIconButton extends StatelessWidget {
  const StyledIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.child,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.borderRadius = 12,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient:
          gradient ??
          (color == null
              ? LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.primaryAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null),
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white, // ensures default text/icon color
      ),
      child: Container(
        padding: padding,
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            ...[const SizedBox(width: 8), icon],
          ],
        ),
      ),
    );
  }
}
