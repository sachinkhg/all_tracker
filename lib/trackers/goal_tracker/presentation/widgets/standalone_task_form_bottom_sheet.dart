/*
 * File: standalone_task_form_bottom_sheet.dart
 *
 * Purpose:
 * - Provides a bottom sheet for creating or editing standalone Task entities (without milestone/goal).
 * - Milestone selection is optional - tasks can be created without milestone.
 * - Supports entry of key Task attributes: name, target date, optional milestone selection, and status.
 */

import 'package:flutter/material.dart';
import '../../../../widgets/date_picker_bottom_sheet.dart';
import '../../../../widgets/context_dropdown_bottom_sheet.dart';

class StandaloneTaskFormBottomSheet extends StatefulWidget {
  final String? initialName;
  final DateTime? initialTargetDate;
  final String? initialMilestoneId;
  final String? initialStatus;
  final List<String>? milestoneOptions; // expects "<id>::<title>" format
  final Map<String, String>? milestoneGoalMap; // milestone id -> goal name (for read-only goal display)
  final Future<void> Function(
    String name,
    DateTime? targetDate,
    String? milestoneId,
    String status,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const StandaloneTaskFormBottomSheet({
    super.key,
    this.initialName,
    this.initialTargetDate,
    this.initialMilestoneId,
    this.initialStatus,
    this.milestoneOptions,
    this.milestoneGoalMap,
    required this.onSubmit,
    this.onDelete,
    this.title = 'Create Task',
  });

  static Future<void> show(
    BuildContext context, {
    String? initialName,
    DateTime? initialTargetDate,
    String? initialMilestoneId,
    String? initialStatus,
    List<String>? milestoneOptions,
    Map<String, String>? milestoneGoalMap,
    required Future<void> Function(
      String name,
      DateTime? targetDate,
      String? milestoneId,
      String status,
    )
        onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Task',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StandaloneTaskFormBottomSheet(
          initialName: initialName,
          initialTargetDate: initialTargetDate,
          initialMilestoneId: initialMilestoneId,
          initialStatus: initialStatus,
          milestoneOptions: milestoneOptions,
          milestoneGoalMap: milestoneGoalMap,
          onSubmit: onSubmit,
          onDelete: onDelete,
          title: title,
        );
      },
    );
  }

  @override
  State<StandaloneTaskFormBottomSheet> createState() => _StandaloneTaskFormBottomSheetState();
}

class _StandaloneTaskFormBottomSheetState extends State<StandaloneTaskFormBottomSheet> {
  late final TextEditingController nameCtrl;

  String? selectedStatus;
  DateTime? selectedDate;

  final List<String> _statusOptions = ['To Do', 'In Progress', 'Complete'];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
    selectedDate = widget.initialTargetDate;
    selectedStatus = widget.initialStatus ?? 'To Do';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleLarge,
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: cs.error),
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.onDelete!();
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task Name
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Target Date Picker
            InkWell(
              onTap: () async {
                final picked = await DatePickerBottomSheet.showDatePickerBottomSheet(
                  context,
                  initialDate: selectedDate,
                );
                if (picked != null) {
                  setState(() {
                    // Handle sentinel value for clear
                    if (picked.millisecondsSinceEpoch == 0) {
                      selectedDate = null;
                    } else {
                      selectedDate = picked;
                    }
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate != null
                          ? formatDate(selectedDate!)
                          : 'Select date (optional)',
                    ),
                    Icon(Icons.calendar_today, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Selector
            InkWell(
              onTap: () async {
                final selected = await ContextDropdownBottomSheet.showContextPicker(
                  context,
                  title: 'Select Status',
                  options: _statusOptions,
                  initialContext: selectedStatus,
                );

                if (selected == '') {
                  // User cleared selection - reset to default
                  setState(() {
                    selectedStatus = 'To Do';
                  });
                } else if (selected != null) {
                  setState(() {
                    selectedStatus = selected;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedStatus ?? 'To Do'),
                    Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task name is required')),
                    );
                    return;
                  }

                  await widget.onSubmit(
                    name,
                    selectedDate,
                    null, // Always null for standalone tasks (no milestone)
                    selectedStatus ?? 'To Do',
                  );
                  
                  // In edit mode, close the form after saving
                  if (widget.onDelete != null) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    return;
                  }
                  
                  // In create mode, clear form and keep it open for adding more
                  nameCtrl.clear();
                  setState(() {
                    selectedDate = null;
                    // Keep selectedMilestoneId and selectedStatus since user might want to add multiple tasks
                  });
                },
                child: Text(widget.onDelete != null ? 'Save' : 'Save and Add More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

