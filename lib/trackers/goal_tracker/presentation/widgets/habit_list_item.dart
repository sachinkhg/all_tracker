import 'package:flutter/material.dart';
import 'package:all_tracker/trackers/goal_tracker/core/app_icons.dart';

/// ---------------------------------------------------------------------------
/// HabitListItem
///
/// File purpose:
/// - Represents a single habit item displayed in a Habit List view.
/// - Dynamically renders habit attributes (name, description, recurrence, target completions,
///   milestone name, goal name, streak) based on the user's selected visibility preferences.
/// - Acts as a presentation-layer widget only; it should not contain business
///   or persistence logic.
///
/// UI behavior and data mapping rules:
/// - Uses a flexible visibility configuration (`visibleFields`) to control
///   which habit attributes are rendered.
/// - Each visibility key corresponds to a standardized presentation key:
///   'name', 'description', 'rrule', 'targetCompletions', 'milestoneName', 'goalName', 'streak', 'isActive'
/// - When `visibleFields` is null, defaults are applied (name + description ON).
///
/// Compatibility guidance:
/// - If additional visibility fields are introduced, always maintain backward
///   compatibility by providing explicit defaults in `_visible()`.
/// - UI should gracefully handle null or missing values for optional fields.
///
/// Developer notes:
/// - Avoid adding stateful behavior or persistence here; this is a stateless,
///   render-only widget.
/// - All formatting (numbers, dates) should remain consistent with the rest
///   of the presentation layer.
/// ---------------------------------------------------------------------------
class HabitListItem extends StatelessWidget {
  /// Unique habit identifier — typically used for edit or navigation callbacks.
  final String id;

  /// Title / name of the habit (required).
  final String title;

  /// Optional description of the habit.
  final String? description;

  /// Recurrence rule for the habit.
  final String rrule;

  /// Target number of completions per occurrence.
  final int? targetCompletions;

  /// Parent milestone name (human-readable label).
  final String? milestoneName;

  /// Parent goal name (human-readable label).
  final String? goalName;

  /// Current streak count.
  final int? currentStreak;

  /// Whether the habit is currently active.
  final bool isActive;

  /// Whether the habit is completed today.
  final bool isCompletedToday;

  /// Triggered when the user taps the item (usually opens the edit screen).
  final VoidCallback onEdit;

  /// Optional callback for toggling completion status.
  final VoidCallback? onToggleCompletion;

  /// Optional callback for viewing habit details.
  final VoidCallback? onViewDetails;

  /// Map of visibility flags that determines which fields are displayed.
  ///
  /// Expected keys:
  /// 'name', 'description', 'rrule', 'targetCompletions', 'milestoneName', 'goalName', 'streak', 'isActive'
  ///
  /// If `null`, defaults are:
  /// - name = true
  /// - description = true
  /// - others = false
  final Map<String, bool>? visibleFields;

  /// Whether the list is currently filtered. Used here for a small visual hint.
  final bool filterActive;

  const HabitListItem({
    super.key,
    required this.id,
    required this.title,
    this.description,
    required this.rrule,
    this.targetCompletions,
    this.milestoneName,
    this.goalName,
    this.currentStreak,
    this.isActive = true,
    this.isCompletedToday = false,
    required this.onEdit,
    this.onToggleCompletion,
    this.onViewDetails,
    this.visibleFields,
    this.filterActive = false,
  });

  /// Determines whether a particular field should be visible in the UI.
  ///
  /// If `visibleFields` is null, defaults to showing only 'name' and 'description'.
  /// This ensures the list remains compact yet informative for new users.
  bool _visible(String key) {
    if (visibleFields == null) {
      // Legacy/default behavior before user customization existed.
      // Ensures backward compatibility with pre-settings versions.
      return (key == 'name' || key == 'description');
    }
    return visibleFields![key] ?? false;
  }

  /// Returns a color for the status badge.
  Color _statusColor(BuildContext context, bool isActive) {
    final cs = Theme.of(context).colorScheme;
    return isActive ? cs.primaryContainer : cs.surfaceVariant;
  }

  Color _statusTextColor(BuildContext context, bool isActive) {
    final cs = Theme.of(context).colorScheme;
    return isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Name + completion toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _visible('name')
                        ? Text(
                            title,
                            style: Theme.of(context).textTheme.labelLarge,
                            softWrap: true,
                          )
                        : const SizedBox.shrink(),
                  ),
                  // View details button
                  if (onViewDetails != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility),
                      tooltip: 'View details',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      iconSize: 18,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ],
                  // Quick completion toggle
                  if (onToggleCompletion != null && isActive) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onToggleCompletion,
                      icon: Icon(
                        isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompletedToday 
                            ? cs.primary 
                            : cs.outline,
                      ),
                      tooltip: isCompletedToday ? 'Mark as incomplete' : 'Mark as complete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      iconSize: 18,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ],
                ],
              ),

              // Description directly below name
              if (_visible('description') && description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                  softWrap: true,
                ),
              ],

              // Status badge
              if (_visible('isActive')) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context, isActive),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _statusTextColor(context, isActive),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Milestone name badge
              if (_visible('milestoneName') && milestoneName != null && milestoneName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.milestone, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Milestone: $milestoneName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],

              // Goal name badge
              if (_visible('goalName') && goalName != null && goalName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.goal, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Goal: $goalName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],

              

              // RRULE, Target Completions, and Streak
              ...() {
                final bool showRrule = _visible('rrule');
                final bool showTarget = _visible('targetCompletions');
                final bool showStreak = _visible('streak');

                if (!(showRrule || showTarget || showStreak)) return <Widget>[];

                final metaWidgets = <Widget>[];

                if (showRrule) {
                  metaWidgets.add(Text(
                    'Recurrence: ${_formatRrule(rrule)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ));
                }

                if (showTarget) {
                  metaWidgets.add(Text(
                    'Target Completion: ${targetCompletions ?? 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ));
                }

                if (showStreak && currentStreak != null && currentStreak! > 0) {
                  metaWidgets.add(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak day streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ));
                }

                return <Widget>[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: metaWidgets.map((w) => Expanded(child: w)).toList(),
                  ),
                ];
              }(),

              // Filter indicator
              if (filterActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Filtered',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRrule(String rrule) {
    // Simple formatting for common RRULE patterns
    if (rrule == 'FREQ=DAILY') return 'Daily';
    if (rrule == 'FREQ=WEEKLY') return 'Weekly';
    if (rrule == 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR') return 'Weekdays';
    if (rrule == 'FREQ=WEEKLY;BYDAY=SA,SU') return 'Weekends';
    if (rrule.startsWith('FREQ=DAILY;INTERVAL=')) {
      final interval = rrule.split('INTERVAL=')[1];
      return 'Every $interval days';
    }
    return rrule; // Return as-is for custom rules
  }
}
