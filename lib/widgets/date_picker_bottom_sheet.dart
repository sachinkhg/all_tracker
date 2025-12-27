// lib/shared/date_picker_bottom_sheet.dart

import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// File purpose:
/// Provides a reusable bottom-sheet UI component for selecting, clearing, or
/// keeping a date. Used across the app wherever a date field requires user
/// input in a consistent and accessible way.
///
/// Developer notes:
/// * This is a pure UI utility — persistence or entity mapping logic should
///   occur in the domain or data layers.
/// * A sentinel value (`DateTime.fromMillisecondsSinceEpoch(0)`) is used to
///   represent an explicit "Clear" action. Callers should interpret this as a
///   deliberate user choice to remove a date value.
/// * The method returns:
///     - `DateTime` (user picked a date via “Set”)
///     - `null` (user cancelled or chose “Keep”, meaning no change)
///     - `DateTime.fromMillisecondsSinceEpoch(0)` (user explicitly cleared)
///
/// Compatibility guidance:
/// * When persisting or serializing this value in Hive/DTOs, handle the sentinel
///   `epoch(0)` consistently to avoid losing intent (“clear” vs “no change”).
/// * Do not encode this sentinel directly in Hive without a conversion layer.
/// * Always document such conversions in `migration_notes.md` if model logic
///   changes.
/// ----------------------------------------------------------------------------

/// Shared date picker bottom sheet component.
///
/// Displays a scrollable calendar picker inside a modal bottom sheet with
/// options to **Keep**, **Clear**, or **Set** the date.
///
/// Returns:
/// - `DateTime` (selected): user picked a date via "Set"
/// - `null`: user cancelled or chose "Keep" (no change)
/// - `DateTime.fromMillisecondsSinceEpoch(0)`: user explicitly chose "Clear"
class DatePickerBottomSheet {
  /// Opens the bottom sheet date picker.
  ///
  /// Parameters:
  ///  - [context]: Required. Flutter build context for modal bottom sheet.
  ///  - [initialDate]: Currently selected date (nullable). Defaults to `now`.
  ///  - [firstDate]/[lastDate]: Define selectable date range.
  ///    Defaults to 2000 through `now.year + 10`.
  ///  - [title]: Optional header displayed at top.
  ///
  /// Returns a [Future<DateTime?>] that completes with:
  ///  - The selected [DateTime] if user taps **Set**.
  ///  - `null` if user taps **Keep** or closes the sheet (no change).
  ///  - `DateTime.fromMillisecondsSinceEpoch(0)` if user taps **Clear**.
  static Future<DateTime?> showDatePickerBottomSheet(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select date',
  }) {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(now.year + 10);

    // Default selection is either the provided initial date or the current date.
    DateTime selected = initialDate ?? now;

    return showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            // Adjust bottom padding dynamically when keyboard is visible.
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ----------------------------------------------------------------
              // Header: Title and close icon (cancel -> null)
              // ----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    // Close without changes → returns null.
                    onPressed: () => Navigator.pop(ctx, null),
                  )
                ],
              ),
              const SizedBox(height: 8),

              // ----------------------------------------------------------------
              // Calendar date picker UI
              // ----------------------------------------------------------------
              SizedBox(
                height: 320,
                child: CalendarDatePicker(
                  initialDate: initialDate ?? now,
                  firstDate: first,
                  lastDate: last,
                  onDateChanged: (d) => selected = d, // Update selected locally
                ),
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------------------
              // Action buttons row
              // ----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Keep -> null (no change)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Keep'),
                  ),
                  const SizedBox(width: 8),
                  // Clear -> sentinel (explicit clear)
                  TextButton(
                    onPressed: () => Navigator.pop(
                        ctx, DateTime.fromMillisecondsSinceEpoch(0)),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  // Set -> return selected value
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: const Text('Set'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
