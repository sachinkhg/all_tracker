import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Defines the **PrimaryAppBar**, a reusable top app bar styled according to
/// the app’s primary color scheme. This ensures consistent header appearance,
/// typography, and action layout across all screens.
///
/// Developer notes:
/// * Centralizes color scheme usage (`colorScheme.primary` / `onPrimary`) for
///   easy theme maintenance.
/// * Intended for screens that use the standard Flutter `AppBar` height.
/// * Keep app-wide actions (like filters, settings, or profile) consistent in
///   positioning by using this shared component.
/// ----------------------------------------------------------------------------

/// A standardized primary-themed [AppBar] used throughout the application.
///
/// Example usage:
/// ```dart
/// Scaffold(
///   appBar: const PrimaryAppBar(
///     title: 'Goals',
///     actions: [IconButton(icon: Icon(Icons.add), onPressed: addGoal)],
///   ),
/// );
/// ```
///
/// Behavior:
/// - Displays the provided [title] as the main header text.
/// - Adopts app theme’s primary colors for background and text.
/// - Supports optional [actions] aligned to the right side of the bar.
class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text displayed in the app bar.
  final String title;

  /// Optional trailing action widgets (e.g., icons or buttons).
  final List<Widget>? actions;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Enhanced icon color for better contrast against gradient background
    final iconColor = cs.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black87;

    // Use themed colors and gradient to maintain consistency across screens.
    return AppBar(
      title: Text(title),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
      backgroundColor: Colors.transparent,
      foregroundColor: cs.onPrimary,
      iconTheme: IconThemeData(
        color: iconColor,
        opacity: 1.0,
      ),
      actionsIconTheme: IconThemeData(
        color: iconColor,
        opacity: 1.0,
      ),
      actions: actions,
      elevation: 0,
    );
  }

  /// Ensures this widget conforms to [PreferredSizeWidget] contract so that
  /// it can be used directly in `Scaffold.appBar`.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
