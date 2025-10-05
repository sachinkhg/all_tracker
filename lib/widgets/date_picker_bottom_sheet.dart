// lib/shared/date_picker_bottom_sheet.dart

import 'package:flutter/material.dart';

/// Shared date picker bottom-sheet.
/// Returns:
/// - DateTime (selected) -> user picked a date via "Set"
/// - null -> user cancelled or chose "Keep" (no change)
/// - DateTime.fromMillisecondsSinceEpoch(0) -> user explicitly chose "Clear"
class DatePickerBottomSheet {
  static Future<DateTime?> showDatePickerBottomSheet(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select date',
  }) {
    final now = DateTime.now();
    final _first = firstDate ?? DateTime(2000);
    final _last = lastDate ?? DateTime(now.year + 10);
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx, null), // Cancel -> no change
                  )
                ],
              ),
              const SizedBox(height: 8),

              // Calendar
              SizedBox(
                height: 320,
                child: CalendarDatePicker(
                  initialDate: initialDate ?? now,
                  firstDate: _first,
                  lastDate: _last,
                  onDateChanged: (d) => selected = d,
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null), // Keep/no change
                    child: const Text('Keep'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(ctx, DateTime.fromMillisecondsSinceEpoch(0)), // Clear sentinel
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
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
