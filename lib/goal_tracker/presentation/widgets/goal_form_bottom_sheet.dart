import 'package:all_tracker/goal_tracker/core/constants.dart';
import 'package:flutter/material.dart';

import '../../../widgets/context_dropdown_bottom_sheet.dart';
import '../../../widgets/date_picker_bottom_sheet.dart';

/// ---------------------------------------------------------------------------
/// GoalFormBottomSheet
///
/// File purpose:
/// - Provides a unified bottom sheet for creating or editing Goal entities.
/// - Supports entry of key Goal attributes: name, description, target date,
///   context, and completion state.
/// - This widget is used for both new-goal creation and goal updates, adapting
///   its layout and available actions (delete/completion checkbox) accordingly.
///
/// Form fields and behavior:
/// - Name and description: standard text input fields.
/// - Context: selected from a list of predefined options using
///   [ContextDropdownBottomSheet].
/// - Target date: chosen via [DatePickerBottomSheet].
/// - Mark as Completed: checkbox, visible only during edit mode (when onDelete
///   is provided).
///
/// Serialization and compatibility notes:
/// - Form inputs map directly to domain entity fields (Goal.name, Goal.desc,
///   Goal.targetDate, Goal.context, Goal.isCompleted).
/// - Nullable values (context, targetDate) are treated as optional.
/// - When modifying parameters or adding new fields:
///   * Update onSubmit signature and ensure existing callers are migrated.
///   * Record field additions or behavioral changes in migration_notes.md.
///
/// Developer guidance:
/// - Keep validation and transformation minimal; domain-level validation
///   should occur in the Goal use cases or repository.
/// - The bottom sheet should not depend on Bloc or Cubit directly; parent
///   layers handle submission and data refresh.
/// - Use Theme colors to maintain consistent look across light/dark modes.
/// ---------------------------------------------------------------------------

class GoalFormBottomSheet {
  /// Displays the goal creation/editing modal sheet.
  ///
  /// [onSubmit] executes when the user taps "Save".
  /// [onDelete] (optional) enables deletion and completion checkbox (edit mode).
  /// [initial*] parameters prefill the form when editing an existing goal.
  ///
  /// Signature:
  /// Future<void> Function(
  ///   String name,
  ///   String desc,
  ///   DateTime? targetDate,
  ///   String? context,
  ///   bool isCompleted,
  /// )
  static Future<void> show(
    BuildContext context, {
    String? initialName,
    String? initialDescription,
    DateTime? initialTargetDate,
    String? initialContext,
    bool initialIsCompleted = false,
    required Future<void> Function(
      String name,
      String desc,
      DateTime? targetDate,
      String? context,
      bool isCompleted,
    )
        onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Goal',
  }) {
    // Text controllers for user input fields
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Mutable local state for context/date selections and completion toggle.
    DateTime? selectedDate = initialTargetDate;
    String? selectedContext = initialContext;
    bool isCompleted = initialIsCompleted;

    // Simple date formatting for display.
    String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Header ---
                    // Displays the form title and optional delete button.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: textTheme.titleLarge),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(Icons.delete, color: cs.error),
                            onPressed: () async {
                              Navigator.pop(ctx2);
                              await onDelete();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Name Field ---
                    // Required; must be non-empty before submission.
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Description Field ---
                    // Optional multi-line text input for goal details.
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // --- Context Selector ---
                    // Displays a dropdown-like row that opens a custom picker.
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Context', style: textTheme.labelLarge),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await ContextDropdownBottomSheet.showContextPicker(
                                    ctx2,
                                    initialContext: selectedContext,
                                    title: 'Select context',
                                    options: kContextOptions,
                                  );
                                  if (picked == null) return;
                                  // Update context selection. Empty strings reset to null.
                                  setState(() => selectedContext = picked.isEmpty ? null : picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedContext ?? 'No context',
                                        style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                      ),
                                      Row(
                                        children: [
                                          if (selectedContext != null)
                                            IconButton(
                                              icon: Icon(Icons.clear, size: 20, color: cs.onSurfaceVariant),
                                              onPressed: () => setState(() => selectedContext = null),
                                            ),
                                          Icon(Icons.arrow_drop_down, size: 24, color: cs.onSurfaceVariant),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // --- Target Date Selector ---
                    // Uses a custom bottom sheet for date picking. Supports clearing.
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target date', style: textTheme.labelLarge),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await DatePickerBottomSheet.showDatePickerBottomSheet(
                                    ctx2,
                                    initialDate: selectedDate,
                                    title: 'Select target date',
                                  );

                                  if (picked == null) return;
                                  // 0 timestamp conventionally means "no date" (reset).
                                  setState(() {
                                    if (picked.millisecondsSinceEpoch == 0) {
                                      selectedDate = null;
                                    } else {
                                      selectedDate = picked;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedDate != null ? formatDate(selectedDate!) : 'No target date',
                                        style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                      ),
                                      Row(
                                        children: [
                                          if (selectedDate != null)
                                            IconButton(
                                              icon: Icon(Icons.clear, size: 20, color: cs.onSurfaceVariant),
                                              onPressed: () => setState(() => selectedDate = null),
                                            ),
                                          Icon(Icons.calendar_today, size: 20, color: cs.onSurfaceVariant),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- Completion Checkbox ---
                    // Appears only in edit mode (when onDelete is provided).
                    if (onDelete != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Completed'),
                        value: isCompleted,
                        onChanged: (val) => setState(() => isCompleted = val ?? false),
                      ),

                    const SizedBox(height: 20),

                    // --- Action Buttons ---
                    // Provides Cancel and Save controls aligned to the right.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            // Minimal validation: name required.
                            if (name.isEmpty) return;
                            await onSubmit(name, desc, selectedDate, selectedContext, isCompleted);
                            // ignore: use_build_context_synchronously
                            Navigator.pop(ctx2);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
