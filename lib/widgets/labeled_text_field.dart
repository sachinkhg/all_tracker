import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Provides a reusable **LabeledTextField** widget that wraps [TextField] with
/// a consistent label and outlined border styling.  
/// It is designed for use across forms and input dialogs where labeled text
/// input fields are required.
///
/// Developer notes:
/// * This widget focuses purely on presentation — validation and controller
///   management should be handled by the parent widget or form logic.
/// * Uses Flutter’s `InputDecoration` for automatic label placement and styling.
/// * Default behavior:
///   - `maxLines = 1` for single-line text fields.
///   - `autofocus = false` to prevent unintentional focus jumps on navigation.
/// ----------------------------------------------------------------------------

/// A labeled [TextField] with a uniform outlined border and configurable
/// line count and autofocus behavior.
///
/// Example usage:
/// ```dart
/// LabeledTextField(
///   controller: titleController,
///   label: 'Goal Title',
/// )
/// ```
///
/// Behavior:
/// - Displays a label above the text input.
/// - Supports single-line or multi-line input based on [maxLines].
/// - Adheres to the app’s theme via the global `InputDecoration` defaults.
class LabeledTextField extends StatelessWidget {
  /// The controller managing the text content of this field.
  final TextEditingController controller;

  /// The label text displayed above the input field.
  final String label;

  /// The maximum number of lines the text field can display.
  /// Defaults to 1 (single-line input).
  final int maxLines;

  /// Whether the text field should gain focus automatically on build.
  /// Defaults to `false`.
  final bool autofocus;

  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}
