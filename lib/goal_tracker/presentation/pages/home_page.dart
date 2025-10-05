// ./lib/goal_tracker/presentation/pages/home_page.dart
/*
  purpose:
    - Defines the app’s landing screen (entry point UI) within the presentation layer.
    - Provides a simple and isolated navigation entry to the [GoalListPage].
    - Designed to be lightweight — contains no business or data logic, only UI and navigation.

  app lifecycle role:
    - Serves as the first interactive page after app initialization and DI setup (see main.dart).
    - Ensures presentation-layer separation: navigation only, no repository or cubit imports.

  navigation & compatibility guidance:
    - Uses [MaterialPageRoute] for navigation to keep navigation stack explicit and simple.
    - If deep-linking, modular routing, or shell navigation is later introduced,
      update this navigation logic and document in ARCHITECTURE.md.
    - Avoid introducing data access or state management here — delegate to downstream pages.
*/

import 'package:flutter/material.dart';

import 'goal_list_page.dart';

/// The app’s landing page providing a single primary action to view all goals.
///
/// This widget is stateless and presentation-only:
/// it defines layout, theming, and navigation behavior.
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
            // Navigate to the goal list page — direct push for simplicity.
            // Keeps navigation logic presentation-focused and decoupled
            // from data-layer or state management dependencies.
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalListPage()),
            );
          },
          child: const Text('Goals', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
