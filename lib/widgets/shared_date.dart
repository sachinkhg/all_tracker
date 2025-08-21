import 'package:flutter/material.dart';

class SharedDate extends StatelessWidget {
  final DateTime date;
  final void Function(DateTime)? onDateChanged; // callback when date changes
  final Color? backgroundColor;
  final Color? textColor;
  final String? label;

  const SharedDate({
    super.key,
    required this.date,
    this.onDateChanged,
    this.backgroundColor,
    this.textColor,
    this.label,
  });

  Future<void> _selectDate(BuildContext context) async {
    // ✅ Close keyboard so picker isn't pushed up
    FocusScope.of(context).unfocus();

    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.onSurface,
              onPrimary: theme.colorScheme.primary,
              onSurface: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.primary, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != date) {
      onDateChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = textColor ?? theme.colorScheme.onPrimary;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.015;
    final borderRadius = BorderRadius.circular(screenWidth * 0.03);
    final fontSize = screenWidth * 0.04;

    // Format date
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final formattedDate = '$day/$month/$year';

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
          const SizedBox(height: 4),
        ],
        Material(
          color: bgColor,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => _selectDate(context),
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
