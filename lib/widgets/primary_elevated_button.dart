import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Defines a reusable **PrimaryElevatedButton** widget that applies consistent
/// theming and layout for elevated buttons across the app. This ensures visual
/// uniformity and centralized control over button color, text style, and icon
/// alignment.
///
/// Developer notes:
/// * This widget wraps Flutter’s [ElevatedButton] but enforces app-specific
///   color and typography rules derived from the current [ThemeData].
/// * Intended for use in primary call-to-action scenarios — use secondary or
///   text buttons for less prominent actions.
/// * Avoid embedding this widget inside another elevated-style container to
///   prevent color conflicts.
/// ----------------------------------------------------------------------------

/// A standardized elevated button with optional icon and consistent primary
/// theme styling.
///
/// Example usage:
/// ```dart
/// PrimaryElevatedButton(
///   label: const Text('Save'),
///   icon: Icons.check,
///   onPressed: saveGoal,
/// )
/// ```
///
/// Design notes:
/// - Uses theme colors (`colorScheme.primary` / `onPrimary`) for background and
///   foreground.
/// - If [icon] is provided, it is automatically spaced with [label] for proper
///   alignment.
/// - Provides consistent padding and corner radius through global theme.
class PrimaryElevatedButton extends StatelessWidget {
  /// The button label (usually a [Text] widget). Required.
  final Widget label;

  /// Optional icon displayed before the label.
  final IconData? icon;

  /// Callback triggered when the button is pressed.
  final VoidCallback onPressed;

  const PrimaryElevatedButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine the child layout:
    //  - Without icon: show label only.
    //  - With icon: show an icon-label row with small horizontal spacing.
    final child = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.onPrimary),
              const SizedBox(width: 8),
              label,
            ],
          );

    // Return a thematically consistent elevated button
    // with the app’s primary color scheme.
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
