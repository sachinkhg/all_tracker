import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Provides a lightweight, reusable widget for displaying error messages with
/// an optional retry action. Commonly used across screens or feature modules
/// to handle API, data, or network failures in a consistent visual style.
///
/// Developer notes:
/// * This widget is intentionally minimal and should not contain any business
///   logic or state management.
/// * Designed for simple error surfaces (e.g., empty state fallback, failed
///   network requests). For full-page error views with illustrations or custom
///   layouts, extend this widget instead of duplicating logic.
/// * When used with async operations, the [onRetry] callback can trigger the
///   same function that initially failed.
/// ----------------------------------------------------------------------------

/// A simple centered error message view with an optional **Retry** button.
///
/// Example usage:
/// ```dart
/// ErrorView(
///   message: 'Failed to load goals',
///   onRetry: () => context.read<GoalCubit>().fetchGoals(),
/// )
/// ```
///
/// Behavior:
/// - Displays the given [message] prefixed with `"Error:"`.
/// - If [onRetry] is provided, shows a **Retry** button.
/// - Designed to fit inside flexible layouts (e.g., `Center`, `Expanded`).
class ErrorView extends StatelessWidget {
  /// The error message to display. Typically short and user-friendly.
  final String message;

  /// Optional callback executed when user taps the **Retry** button.
  /// If null, the button is not displayed.
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display the error message text.
          Text('Error: $message'),
          // Conditionally show the Retry button if callback is provided.
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
