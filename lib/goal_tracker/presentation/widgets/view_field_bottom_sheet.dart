import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// ViewFieldsBottomSheet
///
/// File purpose:
/// - Provides a UI bottom sheet to let users toggle which fields are visible
///   in the Goal list view (Name, Description, Target Date, Context,
///   Remaining Days).
///
/// Notes about persistence / serialization (project-wide guidance):
/// - The view field keys used in this widget ('name', 'description',
///   'targetDate', 'context', 'remainingDays') are the canonical keys used
///   throughout the presentation layer and by any persistence layer that
///   stores view preferences (e.g., Hive box, shared_preferences, JSON).
/// - Serialization rules (recommended):
///   * All keys are optional when reading persisted data. Missing keys should
///     fall back to sensible defaults (see initState defaults below).
///   * Boolean values are expected; if a legacy value is stored as null or
///     a non-boolean, it should be interpreted as the default fallback.
/// - Compatibility guidance:
///   * If you introduce a persisted model (e.g., Hive DTO) for these view
///     preferences, do NOT reuse Hive field numbers across different models.
///     Always allocate new field numbers and record them in
///     migration_notes.md when changing the schema.
///   * When adding new keys, ensure the UI defaults are explicitly set so
///     older persisted records remain compatible.
///
/// Developer directions:
/// - This file is purely presentation/UI. Persistence logic should live in a
///   feature-level repository or a small preferences service under
///   goal_management/features or goal_management/core.
/// - When reading persisted map data into this widget, prefer passing the map
///   via the `initial` constructor parameter so the widget remains UI-only.
///
/// ---------------------------------------------------------------------------

/// A bottom sheet that lets the user choose which fields
/// are visible in the Goal list view.
///
/// By default, Name and Description are ON.
/// Others (Target Date, Context, Remaining Days) are OFF.
enum ViewEntityType { goal, milestone, task, habit }

class ViewFieldsBottomSheet extends StatefulWidget {
  /// Which entity's fields are being configured (goal or milestone).
  final ViewEntityType entity;
  /// Optional initial values provided by the caller.
  ///
  /// Expected shape:
  /// {
  ///   'name': bool?,
  ///   'description': bool?,
  ///   'targetDate': bool?,
  ///   'context': bool?,
  ///   'remainingDays': bool?
  /// }
  ///
  /// Notes:
  /// - Values may come from a persisted source (Hive/shared_prefs). Any missing
  ///   keys are treated as not-present and the widget will use its own defaults.
  /// - Keep the keys consistent across the codebase to avoid accidental
  ///   migration issues. If you change a key name, update migration_notes.md.
  final Map<String, bool>? initial;

  const ViewFieldsBottomSheet({Key? key, required this.entity, this.initial}) : super(key: key);

  @override
  State<ViewFieldsBottomSheet> createState() => _ViewFieldsBottomSheetState();
}

class _ViewFieldsBottomSheetState extends State<ViewFieldsBottomSheet> {
  /// Internal map that drives the UI switches.
  ///
  /// Keys are the canonical field identifiers used across the feature.
  /// This map is intentionally simple (String -> bool) to make it easy to
  /// persist or convert to/from DTOs in the data layer.
  late Map<String, bool> _fields;
  
  /// Whether to save the view preferences to persistent storage.
  /// Checked by default (auto-save enabled).
  /// When unchecked and APPLY is clicked, saved preferences are cleared.
  bool _saveView = true;

  @override
  void initState() {
    super.initState();
    // Build default sets based on entity type; then overlay any provided initial map.
    if (widget.entity == ViewEntityType.goal) {
      _fields = {
        'name': true, // Always enforced ON
        'description': widget.initial?['description'] ?? true,
        'targetDate': widget.initial?['targetDate'] ?? false,
        'context': widget.initial?['context'] ?? false,
        'remainingDays': widget.initial?['remainingDays'] ?? false,
      };
    } else if (widget.entity == ViewEntityType.milestone) {
      // Milestone field set
      _fields = {
        'name': true, // Always enforced ON
        'description': widget.initial?['description'] ?? true,
        'targetDate': widget.initial?['targetDate'] ?? false,
        'goalName': widget.initial?['goalName'] ?? false,
        'plannedValue': widget.initial?['plannedValue'] ?? false,
        'actualValue': widget.initial?['actualValue'] ?? false,
        'remainingDays': widget.initial?['remainingDays'] ?? false,
      };
    } else if (widget.entity == ViewEntityType.task) {
      // Task field set
      _fields = {
        'name': true, // Always enforced ON
        'targetDate': widget.initial?['targetDate'] ?? true,
        'remainingDays': widget.initial?['remainingDays'] ?? false,
        'status': widget.initial?['status'] ?? true,
        'milestoneName': widget.initial?['milestoneName'] ?? false,
        'goalName': widget.initial?['goalName'] ?? false,
      };
    } else if (widget.entity == ViewEntityType.habit) {
      // Habit field set
      _fields = {
        'name': true, // Always enforced ON
        'description': widget.initial?['description'] ?? true,
        'milestoneName': widget.initial?['milestoneName'] ?? false,
        'goalName': widget.initial?['goalName'] ?? false,
        'rrule': widget.initial?['rrule'] ?? false,
        'targetCompletions': widget.initial?['targetCompletions'] ?? false,
      };
    }
  }

  /// Builds a labeled switch row for a given field key.
  ///
  /// The key must be one of the canonical keys documented above. The UI pulls
  /// the current boolean from [_fields]. If a key is missing (shouldn't
  /// normally happen), the switch will show 'false' as a safe fallback.
  Widget _buildToggle(String key, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _fields[key] ?? false,
      onChanged: (val) {
        // Update in-place and rebuild. Keeping the map mutable makes it simple
        // to return directly to callers for persistence (no conversion needed).
        setState(() => _fields[key] = val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Visible Fields',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Name is always visible; toggle removed to guarantee at least one field.
            if (widget.entity == ViewEntityType.goal) ...[
              _buildToggle('description', 'Description'),
              _buildToggle('targetDate', 'Target Date'),
              _buildToggle('context', 'Context'),
              _buildToggle('remainingDays', 'Remaining Days'),
            ] else if (widget.entity == ViewEntityType.milestone) ...[
              _buildToggle('description', 'Description'),
              _buildToggle('targetDate', 'Target Date'),
              _buildToggle('goalName', 'Goal'),
              _buildToggle('plannedValue', 'Planned Value'),
              _buildToggle('actualValue', 'Actual Value'),
              _buildToggle('remainingDays', 'Remaining Days'),
            ] else if (widget.entity == ViewEntityType.task) ...[
              // Task fields
              _buildToggle('targetDate', 'Target Date'),
              _buildToggle('status', 'Status'),
              _buildToggle('milestoneName', 'Milestone'),
              _buildToggle('goalName', 'Goal'),
              _buildToggle('remainingDays', 'Remaining Days'),
            ] else ...[
              // Habit fields
              _buildToggle('description', 'Description'),
              _buildToggle('milestoneName', 'Milestone'),
              _buildToggle('goalName', 'Goal'),
              _buildToggle('rrule', 'Recurrence'),
              _buildToggle('targetCompletions', 'Target Completion'),
            ],
            const SizedBox(height: 8),
            const Divider(),
            CheckboxListTile(
              title: const Text('Save View'),
              subtitle: const Text('Remember these settings for next time'),
              value: _saveView,
              onChanged: (val) {
                setState(() => _saveView = val ?? true);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('APPLY'),
                  onPressed: () {
                    // Ensure 'name' remains enabled
                    _fields['name'] = true;
                    // Return both fields and saveView preference
                    Navigator.of(context).pop({
                      'fields': _fields,
                      'saveView': _saveView,
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
