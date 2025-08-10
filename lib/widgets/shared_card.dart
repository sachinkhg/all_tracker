import 'package:flutter/material.dart';

class SharedCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color inactiveTextColor;
  final Color backgroundColor;

  const SharedCard({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.inactiveTextColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Get the screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate icon size and container size relative to screen width
    final iconContainerSize = screenWidth * 0.12; // 12% of screen width
    final iconSize = iconContainerSize * 0.58; // ~58% inside icon container

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 12),
      decoration: BoxDecoration(color: backgroundColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(iconContainerSize * 0.25),
            ),
            child: Icon(icon, color: textColor, size: iconSize),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        overflow: TextOverflow.ellipsis,
                        fontSize: screenWidth * 0.032,
                      ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: inactiveTextColor,
                        fontSize: screenWidth * 0.032, // Responsive font size (~13px on typical screen)
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
