import 'package:flutter/material.dart';

class SharedDate extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onPressed; // optional tap action
  final Color? backgroundColor;
  final Color? textColor;
  final String? label; // optional label above date (e.g., "Due Date")

  const SharedDate({
    super.key,
    required this.date,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use theme colors if not provided
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = textColor ?? theme.colorScheme.onPrimary;

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.015;
    final borderRadius = BorderRadius.circular(screenWidth * 0.03);
    final fontSize = screenWidth * 0.04;

    // Date formatting
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final formattedDate = '$day/$month/$year';

    // Main content
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, color: fgColor, size: fontSize * 1.2),
        SizedBox(width: screenWidth * 0.02),
        Text(
          formattedDate,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: fontSize * 0.85,
              fontWeight: FontWeight.w500,
              color: fgColor.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 4),
        ],
        Material(
          color: bgColor,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: content,
            ),
          ),
        ),
      ],
    );
  }
}
