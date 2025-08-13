import 'package:flutter/material.dart';

class SharedHeader extends StatelessWidget {
  final Color textColor;
  final VoidCallback? onAddPressed;
  final String title;

  const SharedHeader({
    super.key,
    required this.textColor,
    required this.title,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive values based on screen width
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final verticalPaddingTop = screenWidth * 0.04;
    final verticalPaddingBottom = screenWidth * 0.02;
    final iconButtonSize = screenWidth * 0.12; // icon container size (~48 at 400px width)
    final iconSize = iconButtonSize * 0.5; // icon size relative to container
    final fontSize = screenWidth * 0.05; // font size (~20 at 400px width)

    return Container(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, verticalPaddingTop, horizontalPadding, verticalPaddingBottom),
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: fontSize,
                  ),
            ),
          ),
          // SizedBox(
          //   width: iconButtonSize,
          //   height: iconButtonSize,
          //   child: IconButton(
          //     padding: EdgeInsets.zero,
          //     icon: Icon(Icons.add, color: textColor, size: iconSize),
          //     onPressed: onAddPressed,
          //     tooltip: 'Add Goal',
          //   ),
          // ),
        ],
      ),
    );
  }
}
