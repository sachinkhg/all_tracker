import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Provides a standardized **EmptyState** widget for displaying friendly,
/// minimal messages when a screen or list has no data to show.  
/// Ensures a consistent visual pattern for "no content" situations across
/// the app (e.g., no goals, no history, no search results).
///
/// Developer notes:
/// * This widget is intentionally simple and stateless — it should not handle
///   refresh logic or conditional rendering.
/// * For complex empty states (e.g., illustrations, actions), extend this
///   component rather than recreating from scratch.
/// * Keep messages short, neutral, and user-oriented (e.g., “No goals yet.”).
/// ----------------------------------------------------------------------------

/// Displays a centered empty-state message.
///
/// Example usage:
/// ```dart
/// const EmptyState(message: 'No goals added yet.');
/// ```
///
/// Behavior:
/// - Centers the provided [message] on the screen.
/// - Intended to be used within containers such as `Expanded` or `Scaffold.body`.
class EmptyState extends StatelessWidget {
  /// The message to display when the view has no data.
  final String message;

  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        // Display message centered both vertically and horizontally.
        child: Text(message),
      );
}
