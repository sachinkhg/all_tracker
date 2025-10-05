import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Defines a reusable **LoadingView** widget used to indicate ongoing
/// background operations such as API calls, data sync, or initialization steps.
/// It provides a consistent loading indicator and optional descriptive message
/// across the app.
///
/// Developer notes:
/// * This widget focuses purely on UI feedback — no business logic or
///   async management should be embedded here.
/// * The default spinner color adapts to the current theme’s `colorScheme.primary`.
/// * Keep the loading message concise and user-friendly; prefer neutral language
///   (“Loading goals…”, “Syncing data…”) rather than technical terms.
/// ----------------------------------------------------------------------------

/// A simple centered loading indicator with an optional message.
///
/// Example usage:
/// ```dart
/// const LoadingView(message: 'Loading your goals...');
/// ```
///
/// Behavior:
/// - Always centers content both horizontally and vertically.
/// - Displays a [CircularProgressIndicator] styled with the theme’s primary color.
/// - Optionally shows a text message below the spinner.
class LoadingView extends StatelessWidget {
  /// Optional message displayed under the loading indicator.
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary progress indicator (themed)
          CircularProgressIndicator(color: cs.primary),

          // Optional message displayed below the spinner.
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
