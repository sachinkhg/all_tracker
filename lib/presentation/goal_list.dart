import 'package:flutter/material.dart';

class Goal {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;

  Goal({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
  });
}

class GoalsListPage extends StatelessWidget {
  GoalsListPage({super.key});

  // Sample data for goals
  final List<Goal> goals = [
    Goal(
      icon: Icons.public,
      iconBackgroundColor: Color(0xFF2d372a),
      title: 'Learn a new language',
      subtitle: 'Complete 5 tasks',
    ),
    Goal(
      icon: Icons.book,
      iconBackgroundColor: Color(0xFF2d372a),
      title: 'Read 10 books',
      subtitle: 'Complete 3 tasks',
    ),
    Goal(
      icon: Icons.emoji_events,
      iconBackgroundColor: Color(0xFF2d372a),
      title: 'Run a marathon',
      subtitle: 'Complete 2 tasks',
    ),
    Goal(
      icon: Icons.place,
      iconBackgroundColor: Color(0xFF2d372a),
      title: 'Travel to a new country',
      subtitle: 'Complete 4 tasks',
    ),
  ];



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

      final Color backgroundColor = theme.colorScheme.primary;
      final Color textColor = theme.colorScheme.onPrimary;
      final Color inactiveNavColor = theme.colorScheme.primary.withAlpha(150);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and add button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Goals',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.add, color: textColor, size: 24),
                      onPressed: () {
                        // Add goal action
                      },
                      tooltip: 'Add Goal',
                    ),
                  ),
                ],
              ),
            ),

            // Goals List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: goal.iconBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(goal.icon, color: textColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                goal.title,
                                style: theme.textTheme.bodyLarge?.copyWith(                                
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: inactiveNavColor,
                                  fontSize: 13,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
