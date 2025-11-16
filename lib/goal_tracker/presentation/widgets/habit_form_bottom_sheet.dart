import 'package:flutter/material.dart';
import '../../../widgets/context_dropdown_bottom_sheet.dart';

/// Bottom sheet for creating and editing habits.
///
/// This widget provides a form interface for habit creation and editing,
/// following the same pattern as other form bottom sheets in the app.
/// It includes milestone selection with auto-assignment of goalId,
/// RRULE input with presets, and validation.
class HabitFormBottomSheet extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialMilestoneId;
  final String? initialRrule;
  final int? initialTargetCompletions;
  final bool initialIsActive;
  final List<String>? milestoneOptions; // expects "<id>::<title>" format
  final Map<String, String>? milestoneGoalMap; // milestone id -> goal name (for read-only goal display)
  final Future<void> Function(
    String name,
    String? description,
    String milestoneId,
    String rrule,
    int? targetCompletions,
    bool isActive,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const HabitFormBottomSheet({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialMilestoneId,
    this.initialRrule,
    this.initialTargetCompletions,
    this.initialIsActive = true,
    this.milestoneOptions,
    this.milestoneGoalMap,
    required this.onSubmit,
    this.onDelete,
    this.title = 'Create Habit',
  });

  static Future<void> show(
    BuildContext context, {
    String? initialName,
    String? initialDescription,
    String? initialMilestoneId,
    String? initialRrule,
    int? initialTargetCompletions,
    bool initialIsActive = true,
    List<String>? milestoneOptions,
    Map<String, String>? milestoneGoalMap,
    required Future<void> Function(
      String name,
      String? description,
      String milestoneId,
      String rrule,
      int? targetCompletions,
      bool isActive,
    )
        onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Habit',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return HabitFormBottomSheet(
          initialName: initialName,
          initialDescription: initialDescription,
          initialMilestoneId: initialMilestoneId,
          initialRrule: initialRrule,
          initialTargetCompletions: initialTargetCompletions,
          initialIsActive: initialIsActive,
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
  State<HabitFormBottomSheet> createState() => _HabitFormBottomSheetState();
}

class _HabitFormBottomSheetState extends State<HabitFormBottomSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController targetCompletionsCtrl;
  late final TextEditingController customRruleCtrl;

  late final List<String> _milestoneTitles;
  late final Map<String, String> _idToTitle; // milestone id -> title
  late final Map<String, String> _titleToId; // title -> milestone id (first match)
  String? selectedMilestoneId;
  String? selectedRrulePreset;
  String? customRrule;
  int? targetCompletions;
  bool isActive = true;
  bool useCustomRrule = false;

  // RRULE presets for common patterns
  final Map<String, String> _rrulePresets = {
    'Daily': 'FREQ=DAILY',
    'Weekdays': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    'Weekends': 'FREQ=WEEKLY;BYDAY=SA,SU',
    'Weekly': 'FREQ=WEEKLY',
    'Every 2 days': 'FREQ=DAILY;INTERVAL=2',
    'Every 3 days': 'FREQ=DAILY;INTERVAL=3',
    'Custom': 'CUSTOM',
  };

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
    descriptionCtrl = TextEditingController(text: widget.initialDescription ?? '');
    targetCompletionsCtrl = TextEditingController(text: widget.initialTargetCompletions?.toString() ?? '');
    customRruleCtrl = TextEditingController(text: widget.initialRrule ?? '');
    
    isActive = widget.initialIsActive;
    
    // Initialize RRULE selection
    if (widget.initialRrule != null && widget.initialRrule!.isNotEmpty) {
      // Check if it matches a preset
      final matchingPreset = _rrulePresets.entries
          .where((entry) => entry.value == widget.initialRrule)
          .map((entry) => entry.key)
          .firstOrNull;
      
      if (matchingPreset != null) {
        selectedRrulePreset = matchingPreset;
        useCustomRrule = false;
      } else {
        customRrule = widget.initialRrule;
        selectedRrulePreset = 'Custom';
        useCustomRrule = true;
      }
    } else {
      selectedRrulePreset = 'Daily';
      useCustomRrule = false;
    }

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
    descriptionCtrl.dispose();
    targetCompletionsCtrl.dispose();
    customRruleCtrl.dispose();
    super.dispose();
  }

  /// Returns the goal name for the currently selected milestone (read-only display).
  String? get selectedGoalName {
    if (selectedMilestoneId == null || widget.milestoneGoalMap == null) return null;
    return widget.milestoneGoalMap![selectedMilestoneId!];
  }

  String _getCurrentRrule() {
    if (useCustomRrule) {
      return customRruleCtrl.text.trim();
    }
    return _rrulePresets[selectedRrulePreset]!;
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
            // Header
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

            // Habit Name
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Icon(Icons.lock, size: 16, color: cs.onSurfaceVariant.withOpacity(0.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // RRULE Selection
            InkWell(
              onTap: () async {
                final selected = await ContextDropdownBottomSheet.showContextPicker(
                  context,
                  title: 'Select Recurrence',
                  options: _rrulePresets.keys.toList(),
                  initialContext: selectedRrulePreset,
                );

                if (selected == '') {
                  // User cleared selection - reset to default
                  setState(() {
                    selectedRrulePreset = 'Daily';
                    useCustomRrule = false;
                  });
                } else if (selected != null) {
                  setState(() {
                    if (selected == 'Custom') {
                      useCustomRrule = true;
                      selectedRrulePreset = 'Custom';
                    } else {
                      useCustomRrule = false;
                      selectedRrulePreset = selected;
                    }
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Recurrence *',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedRrulePreset ?? 'Daily'),
                    Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (useCustomRrule) ...[
              const SizedBox(height: 16),
              TextField(
                controller: customRruleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom RRULE',
                  hintText: 'FREQ=DAILY;INTERVAL=2',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Target Completions
            TextField(
              controller: targetCompletionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Completions',
                hintText: '1 (default)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Active toggle
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (can be completed)'),
              value: isActive,
              onChanged: (val) => setState(() => isActive = val ?? true),
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
                      const SnackBar(content: Text('Habit name is required')),
                    );
                    return;
                  }

                  if (selectedMilestoneId == null || selectedMilestoneId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a milestone')),
                    );
                    return;
                  }

                  final rrule = _getCurrentRrule();
                  if (rrule.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid recurrence rule')),
                    );
                    return;
                  }

                  final targetCompletions = targetCompletionsCtrl.text.trim().isEmpty
                      ? null
                      : int.tryParse(targetCompletionsCtrl.text.trim());

                  await widget.onSubmit(
                    name,
                    descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
                    selectedMilestoneId!,
                    rrule,
                    targetCompletions,
                    isActive,
                  );
                  
                  // In edit mode, close the form after saving
                  if (widget.onDelete != null) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    return;
                  }
                  
                  // In create mode, clear form and keep it open for adding more
                  // Keep selectedMilestoneId since user might want to add multiple habits to same milestone
                  nameCtrl.clear();
                  descriptionCtrl.clear();
                  targetCompletionsCtrl.clear();
                  setState(() {
                    // Keep selectedMilestoneId - don't clear it
                    // Reset RRULE to default
                    selectedRrulePreset = 'Daily';
                    useCustomRrule = false;
                    customRruleCtrl.clear();
                    isActive = true;
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
