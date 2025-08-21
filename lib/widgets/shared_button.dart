import 'package:flutter/material.dart';

class SharedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final int styleType; // 1 = regular button, 2 = text button

  const SharedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.styleType = 1, // Default to existing style
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use theme colors if not provided
    final btnBackground = backgroundColor ?? theme.colorScheme.onPrimary;
    final btnTextColor = textColor ?? theme.colorScheme.onSurface;

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.05; // 5% of width
    final verticalPadding = screenHeight * 0.015; // 1.5% of height
    final borderRadius = BorderRadius.circular(screenWidth * 0.03);
    final fontSize = screenWidth * 0.04; // ~4% of width

    if (styleType == 2) {
      // Text style button (No padding / background / border)
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: btnTextColor, size: fontSize * 1.2),
              SizedBox(width: screenWidth * 0.02),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: btnTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Default style
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnBackground,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: btnTextColor, size: fontSize * 1.2),
            SizedBox(width: screenWidth * 0.02),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: btnTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
