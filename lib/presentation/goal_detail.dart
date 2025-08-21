import 'package:flutter/material.dart';
import '/widgets/shared_header.dart';
// Assume you have these shared widgets based on your previous samples:
import '/widgets/shared_card.dart';

class GoalDetailPage extends StatelessWidget {
  final String goalTitle;
  final String goalDescription;
  final DateTime targetDate;
  final List<Milestone> milestones;
  final VoidCallback? onEditGoal;
  final VoidCallback? onAddMilestone;

  const GoalDetailPage({
    super.key,
    required this.goalTitle,
    required this.goalDescription,
    required this.targetDate,
    required this.milestones,
    this.onEditGoal,
    this.onAddMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final textColor = theme.colorScheme.onPrimary;
    final backgroundColor = theme.colorScheme.primary;
    final inactiveTextColor = theme.disabledColor;

    // Responsive paddings
    final sidePadding = screenWidth * 0.04;
    final sectionSpacing = screenWidth * 0.04;
    final buttonHeight = screenWidth * 0.13;
    final buttonFontSize = screenWidth * 0.044;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SharedHeader(
              title: '',
              textColor: textColor,
              onAddPressed: onEditGoal,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sectionSpacing),
                    Text(
                      goalTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: screenWidth * 0.065, // ~26 on 400px width
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      goalDescription,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: inactiveTextColor,
                        fontSize: screenWidth * 0.044,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: inactiveTextColor, size: screenWidth * 0.055),
                        SizedBox(width: screenWidth * 0.013),
                        Text(
                          'Target Date',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: inactiveTextColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatDate(targetDate),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontSize: screenWidth * 0.048,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    Text(
                      'Milestones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: screenWidth * 0.052,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Column(
                      children: milestones
                          .asMap()
                          .entries
                          .map(
                            (entry) => SharedCard(
                              icon: Icons.flag,
                              iconBackgroundColor: theme.colorScheme.secondary.withAlpha(150),
                              title: 'Milestone ${entry.key + 1}',
                              subtitle1: entry.value.title,
                              textColor: textColor,
                              inactiveTextColor: inactiveTextColor,
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: theme.colorScheme.onSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
                              ),
                              onPressed: onAddMilestone,
                              child: const Text('Add Milestone'),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.secondary,
                                side: BorderSide(color: theme.colorScheme.secondary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.bold),
                              ),
                              onPressed: onEditGoal,
                              child: const Text('Edit Goal'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing * 1.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Example: December 31, 2024
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}

class Milestone {
  final String title;
  const Milestone(this.title);
}
