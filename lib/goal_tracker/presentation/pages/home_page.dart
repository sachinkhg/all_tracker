import 'package:flutter/material.dart';

import 'goal_list_page.dart';

/// Landing page for the app. Provides a single primary action to navigate to
/// the goals list page. Keeps presentation-layer imports only.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AllTracker'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            // Navigate to the goal list page. Uses a direct push so this file does
            // not depend on any data-layer implementation.
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalListPage()));
          },
          child: const Text('Goals', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
