import 'package:flutter/material.dart';

class SquareButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const SquareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final btnBackground = backgroundColor ?? theme.colorScheme.primary;
    final btnTextColor = textColor ?? theme.colorScheme.onPrimary;

    // Use screen width to maintain responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.22; // 22% of width → square

    final borderRadius = BorderRadius.circular(screenWidth * 0.04);
    final fontSize = screenWidth * 0.035;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnBackground,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          elevation: 3,
          padding: EdgeInsets.all(screenWidth * 0.02),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: btnTextColor, size: fontSize * 1.6),
              SizedBox(height: screenWidth * 0.015),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: fontSize,
                  color: btnTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
