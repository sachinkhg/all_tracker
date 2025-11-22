import 'package:flutter/material.dart';

/// Bottom sheet for editing itinerary day notes.
class ItineraryDayNotesFormBottomSheet {
  static Future<String?> show(
    BuildContext context, {
    String? initialNotes,
  }) {
    final notesCtrl = TextEditingController(text: initialNotes ?? '');

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Day Notes',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(ctx, null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Notes Field ---
                TextField(
                  controller: notesCtrl,
                  style: TextStyle(color: cs.primary),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: const OutlineInputBorder(),
                    hintText: 'Add notes for this day...',
                  ),
                  maxLines: 5,
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // --- Action Button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final notes = notesCtrl.text.trim();
                      // Return empty string for cleared notes (will be converted to null)
                      // Return null only when user cancels
                      Navigator.pop(ctx, notes);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

