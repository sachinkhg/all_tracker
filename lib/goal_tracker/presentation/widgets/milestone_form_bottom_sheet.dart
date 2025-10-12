/*
 * File: milestone_form_bottom_sheet.dart
 *
 * Purpose:
 * - Provides a unified bottom sheet for creating or editing Milestone entities.
 * - Supports entry of key Milestone attributes: name, description, planned value,
 *   actual value, target date, and parent goal selection (goalId).
 * - Goal selection is a strict dropdown (titles only). Selecting a title chooses
 *   the underlying goal id which is sent on submit.
 */

import 'package:flutter/material.dart';
import '../../../widgets/date_picker_bottom_sheet.dart';
import '../../../widgets/context_dropdown_bottom_sheet.dart';

class MilestoneFormBottomSheet extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final double? initialPlannedValue;
  final double? initialActualValue;
  final DateTime? initialTargetDate;
  final String? initialGoalId;
  final List<String>? goalOptions; // expects "<id>::<title>" or "title"
  final Future<void> Function(
    String name,
    String? description,
    double? plannedValue,
    double? actualValue,
    DateTime? targetDate,
    String goalId,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const MilestoneFormBottomSheet({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialPlannedValue,
    this.initialActualValue,
    this.initialTargetDate,
    this.initialGoalId,
    this.goalOptions,
    required this.onSubmit,
    this.onDelete,
    this.title = 'Create Milestone',
  });

  static Future<void> show(
    BuildContext context, {
    String? initialName,
    String? initialDescription,
    double? initialPlannedValue,
    double? initialActualValue,
    DateTime? initialTargetDate,
    String? initialGoalId,
    List<String>? goalOptions,
    required Future<void> Function(
      String name,
      String? description,
      double? plannedValue,
      double? actualValue,
      DateTime? targetDate,
      String goalId,
    )
        onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Milestone',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return MilestoneFormBottomSheet(
          initialName: initialName,
          initialDescription: initialDescription,
          initialPlannedValue: initialPlannedValue,
          initialActualValue: initialActualValue,
          initialTargetDate: initialTargetDate,
          initialGoalId: initialGoalId,
          goalOptions: goalOptions,
          onSubmit: onSubmit,
          onDelete: onDelete,
          title: title,
        );
      },
    );
  }

  @override
  State<MilestoneFormBottomSheet> createState() => _MilestoneFormBottomSheetState();
}

class _MilestoneFormBottomSheetState extends State<MilestoneFormBottomSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController plannedCtrl;
  late final TextEditingController actualCtrl;

  late final List<String> _goalTitles;
  late final Map<String, String> _idToTitle; // id -> title
  late final Map<String, String> _titleToId; // title -> id (first match)
  String? selectedGoalId;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
    descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    plannedCtrl = TextEditingController(text: widget.initialPlannedValue?.toString() ?? '');
    actualCtrl = TextEditingController(text: widget.initialActualValue?.toString() ?? '');

    selectedDate = widget.initialTargetDate;

    final cleanedOptions = (widget.goalOptions ?? [])
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
    _goalTitles = pairs.map((e) => e.value).toList(growable: false);

    if (_idToTitle.isNotEmpty && widget.initialGoalId != null && widget.initialGoalId!.isNotEmpty) {
      if (_idToTitle.containsKey(widget.initialGoalId)) selectedGoalId = widget.initialGoalId;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    plannedCtrl.dispose();
    actualCtrl.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // No need for raw parsing helpers; shared GoalDropdown uses id/title directly.

  double? parseDoubleOrNull(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.trim());
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: textTheme.titleLarge),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: cs.error),
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.onDelete!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

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

            TextField(
              controller: plannedCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: cs.primary),
              decoration: InputDecoration(
                labelText: 'Planned value (optional)',
                labelStyle: TextStyle(color: cs.onSurfaceVariant),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: actualCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: cs.primary),
              decoration: InputDecoration(
                labelText: 'Actual value (optional)',
                labelStyle: TextStyle(color: cs.onSurfaceVariant),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal', style: textTheme.labelLarge),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _goalTitles.isEmpty
                      ? null
                      : () async {
                          final picked = await ContextDropdownBottomSheet.showContextPicker(
                            context,
                            initialContext: selectedGoalId == null ? null : _idToTitle[selectedGoalId!],
                            title: 'Select goal',
                            options: _goalTitles,
                          );
                          if (picked == null) return; // cancel => no change
                          if (picked.isEmpty) {
                            setState(() => selectedGoalId = null); // clear
                            return;
                          }
                          final id = _titleToId[picked];
                          if (id == null || id.isEmpty) return;
                          setState(() => selectedGoalId = id);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Builder(builder: (context) {
                            final String displayText = selectedGoalId == null
                                ? (_goalTitles.isEmpty ? 'No goals available' : 'No goal')
                                : (_idToTitle[selectedGoalId!] ?? '');
                            return Tooltip(
                              message: displayText.isEmpty ? null : displayText,
                              waitDuration: const Duration(milliseconds: 600),
                              child: Text(
                                displayText,
                                style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            );
                          }),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedGoalId != null)
                              IconButton(
                                icon: Icon(Icons.clear, size: 20, color: cs.onSurfaceVariant),
                                onPressed: () => setState(() => selectedGoalId = null),
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

            const SizedBox(height: 12),

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
                            context,
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
                            border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
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

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                    final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a milestone name')),
                      );
                      return;
                    }

                    if (selectedGoalId == null || selectedGoalId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a goal')),
                      );
                      return;
                    }

                    final gid = selectedGoalId!;
                    if (gid.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid goal selection')),
                      );
                      return;
                    }

                    final planned = parseDoubleOrNull(plannedCtrl.text);
                    final actual = parseDoubleOrNull(actualCtrl.text);

                    await widget.onSubmit(name, desc, planned, actual, selectedDate, gid);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
