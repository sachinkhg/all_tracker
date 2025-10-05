import 'package:all_tracker/goal_tracker/core/constants.dart';
import 'package:all_tracker/widgets/primary_elevated_button.dart';
import 'package:flutter/material.dart';

import '../../../widgets/context_dropdown_bottom_sheet.dart';
import '../../../widgets/date_picker_bottom_sheet.dart';

/// Goal form bottom sheet updated to include Target Date, Context, and Completion check.
/// onSubmit signature: Future<void> Function(String name, String desc, DateTime? targetDate, String? context, bool isCompleted)
class GoalFormBottomSheet {
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
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    DateTime? selectedDate = initialTargetDate;
    String? selectedContext = initialContext;
    bool isCompleted = initialIsCompleted;

    String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
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
                    // Header Row with Title + Delete (if edit mode)
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

                    // Name
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

                    // Description
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

                    // Context row (dropdown)
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

                    // Target Date row
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
                                        selectedDate != null ? _formatDate(selectedDate!) : 'No target date',
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

                    //"Mark as Completed" checkbox (visible only in Edit mode)
                    if (onDelete != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Completed'),
                        value: isCompleted,
                        onChanged: (val) => setState(() => isCompleted = val ?? false),
                      ),

                    const SizedBox(height: 20),

                    // Action buttons
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
