/*
 * File: task_form_bottom_sheet.dart
 *
 * Purpose:
 * - Provides a unified bottom sheet for creating or editing Task entities.
 * - Supports entry of key Task attributes: name, target date, milestone selection, and status.
 * - **CRITICAL BEHAVIOR**: Goal field is READ-ONLY and auto-updates when milestone changes.
 *   User cannot directly select a goal; it's derived from the selected milestone.
 * - Milestone selection is a strict dropdown (titles only). Selecting a title chooses
 *   the underlying milestone id which is sent on submit.
 * - Validates that a milestone is selected before allowing form submission.
 */

import 'package:flutter/material.dart';
import '../../../../widgets/date_picker_bottom_sheet.dart';
import '../../../../widgets/context_dropdown_bottom_sheet.dart';

class TaskFormBottomSheet extends StatefulWidget {
  final String? initialName;
  final DateTime? initialTargetDate;
  final String? initialMilestoneId;
  final String? initialStatus;
  final List<String>? milestoneOptions; // expects "<id>::<title>" format
  final Map<String, String>? milestoneGoalMap; // milestone id -> goal name (for read-only goal display)
  final Future<void> Function(
    String name,
    DateTime? targetDate,
    String milestoneId,
    String status,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const TaskFormBottomSheet({
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
      String milestoneId,
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
        return TaskFormBottomSheet(
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
  State<TaskFormBottomSheet> createState() => _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  late final TextEditingController nameCtrl;

  late final List<String> _milestoneTitles;
  late final Map<String, String> _idToTitle; // milestone id -> title
  late final Map<String, String> _titleToId; // title -> milestone id (first match)
  String? selectedMilestoneId;
  String? selectedStatus;
  DateTime? selectedDate;

  final List<String> _statusOptions = ['To Do', 'In Progress', 'Complete'];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
    selectedDate = widget.initialTargetDate;
    selectedStatus = widget.initialStatus ?? 'To Do';

    final cleanedOptions = (widget.milestoneOptions ?? [])
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList(growable: false);

    // Build mappings between ids and titles from raw strings
    final List<MapEntry<String, String>> pairs = cleanedOptions.map((raw) {
      if (raw.contains('::')) {
        final parts = raw.split('::');
        final id = parts.first.trim();
        final title = parts.sublist(1).join('::').trim();
        return MapEntry(id, title);
      }
      final trimmed = raw.trim();
      return MapEntry(trimmed, trimmed);
    }).toList(growable: false);

    _idToTitle = {for (final p in pairs) p.key: p.value};
    _titleToId = {};
    for (final p in pairs) {
      // First title occurrence wins; avoids flicker if duplicates
      _titleToId.putIfAbsent(p.value, () => p.key);
    }
    _milestoneTitles = pairs.map((e) => e.value).toList(growable: false);

    if (_idToTitle.isNotEmpty && widget.initialMilestoneId != null && widget.initialMilestoneId!.isNotEmpty) {
      if (_idToTitle.containsKey(widget.initialMilestoneId)) {
        selectedMilestoneId = widget.initialMilestoneId;
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Returns the goal name for the currently selected milestone (read-only display).
  String? get selectedGoalName {
    if (selectedMilestoneId == null || widget.milestoneGoalMap == null) return null;
    return widget.milestoneGoalMap![selectedMilestoneId!];
  }

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

            // Milestone Selector (Required)
            InkWell(
              onTap: () async {
                if (_milestoneTitles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No milestones available')),
                  );
                  return;
                }

                final selected = await ContextDropdownBottomSheet.showContextPicker(
                  context,
                  title: 'Select Milestone',
                  options: _milestoneTitles,
                  initialContext: selectedMilestoneId != null
                      ? _idToTitle[selectedMilestoneId!]
                      : null,
                );

                if (selected == '') {
                  // User cleared selection
                  setState(() {
                    selectedMilestoneId = null;
                  });
                } else if (selected != null && _titleToId.containsKey(selected)) {
                  setState(() {
                    selectedMilestoneId = _titleToId[selected]!;
                    // Goal display will auto-update via selectedGoalName getter
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Milestone *',
                  border: const OutlineInputBorder(),
                  errorText: selectedMilestoneId == null ? 'Milestone is required' : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedMilestoneId != null
                            ? _idToTitle[selectedMilestoneId!] ?? 'Unknown'
                            : 'Select Milestone',
                        style: TextStyle(
                          color: selectedMilestoneId == null ? cs.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Goal Display (Read-Only)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Goal (auto-set from milestone)',
                border: OutlineInputBorder(),
                enabled: false,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedGoalName ?? '(Select a milestone first)',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Icon(Icons.lock, size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                ],
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

                  if (selectedMilestoneId == null || selectedMilestoneId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a milestone')),
                    );
                    return;
                  }

                  await widget.onSubmit(
                    name,
                    selectedDate,
                    selectedMilestoneId!,
                    selectedStatus ?? 'To Do',
                  );
                  
                  // In edit mode, close the form after saving
                  if (widget.onDelete != null) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    return;
                  }
                  
                  // In create mode, clear form and keep it open for adding more
                  // Keep selectedMilestoneId and selectedStatus since user might want to add multiple tasks
                  nameCtrl.clear();
                  setState(() {
                    selectedDate = null;
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

