import 'package:flutter/material.dart';
import '/widgets/shared_list_page.dart';
import '/widgets/shared_card.dart';

class Goal {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;

  const Goal({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
  });
}

class GoalsListPage extends StatelessWidget {
  final List<Goal> goals = const [
    Goal(
      icon: Icons.public,
      iconBackgroundColor: Color(0xFF2d372a),
      title: 'Learn new language',
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
    // Add more goals here...
  ];

  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedListPage<Goal>(
      items: goals,
      onAddPressed: () {
        // Handle add goal
      },
      itemBuilder: (context, goal) {
        final theme = Theme.of(context);
        return SharedCard(
          icon: goal.icon,
          iconBackgroundColor: goal.iconBackgroundColor,
          title: goal.title,
          subtitle: goal.subtitle,
          textColor: theme.colorScheme.onPrimary,
          inactiveTextColor: theme.colorScheme.onPrimary,
          backgroundColor: theme.colorScheme.primary,
        );
      },
    );
  }
}
