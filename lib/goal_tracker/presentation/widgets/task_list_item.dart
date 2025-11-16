import 'package:flutter/material.dart';
import 'package:all_tracker/goal_tracker/core/app_icons.dart';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// TaskListItem
///
/// File purpose:
/// - Represents a single task item displayed in a Task List view.
/// - Dynamically renders task attributes (name, target date, status, milestone name,
///   goal name, remaining days) based on the user's selected visibility preferences.
/// - Acts as a presentation-layer widget only; it should not contain business
///   or persistence logic.
///
/// UI behavior and data mapping rules:
/// - Uses a flexible visibility configuration (`visibleFields`) to control
///   which task attributes are rendered.
/// - Each visibility key corresponds to a standardized presentation key:
///   'name', 'targetDate', 'status', 'milestoneName', 'goalName', 'remainingDays'
/// - When `visibleFields` is null, defaults are applied (name + status + targetDate ON).
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
class TaskListItem extends StatelessWidget {
  /// Unique task identifier — typically used for edit or navigation callbacks.
  final String id;

  /// Title / name of the task (required).
  final String title;

  /// Optional target date for the task.
  final DateTime? targetDate;

  /// Current status of the task.
  final String status;

  /// Parent milestone name (human-readable label).
  final String? milestoneName;

  /// Parent goal name (human-readable label).
  final String? goalName;

  /// Triggered when the user taps the item (usually opens the edit screen).
  final VoidCallback onEdit;

  /// Optional callback triggered when the user swipes right to mark task as completed.
  /// If null, swipe gesture is disabled.
  final VoidCallback? onSwipeComplete;

  /// Map of visibility flags that determines which fields are displayed.
  ///
  /// Expected keys:
  /// 'name', 'targetDate', 'status', 'milestoneName', 'goalName', 'remainingDays'
  ///
  /// If `null`, defaults are:
  /// - name = true
  /// - targetDate = true
  /// - status = true
  /// - others = false
  final Map<String, bool>? visibleFields;

  /// Whether the list is currently filtered. Used here for a small visual hint.
  final bool filterActive;

  const TaskListItem({
    super.key,
    required this.id,
    required this.title,
    this.targetDate,
    required this.status,
    this.milestoneName,
    this.goalName,
    required this.onEdit,
    this.onSwipeComplete,
    this.visibleFields,
    this.filterActive = false,
  });

  /// Returns the number of days remaining until the target date.
  int? get remainingDays {
    if (targetDate == null) return null;
    final today = DateTime.now();
    return targetDate!.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  /// Determines whether a particular field should be visible in the UI.
  bool _visible(String key) {
    if (visibleFields == null) {
      // Default: name, status, targetDate
      return (key == 'name' || key == 'status' || key == 'targetDate');
    }
    return visibleFields![key] ?? false;
  }

  /// Returns a color for the status badge.
  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'Complete':
        return cs.tertiaryContainer;
      case 'In Progress':
        return cs.primaryContainer;
      case 'To Do':
      default:
        return cs.secondaryContainer;
    }
  }

  Color _statusTextColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'Complete':
        return cs.onTertiaryContainer;
      case 'In Progress':
        return cs.onPrimaryContainer;
      case 'To Do':
      default:
        return cs.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy');

    final formattedTarget = targetDate != null ? dateFmt.format(targetDate!) : null;

    // Only enable swipe if callback is provided and task is not already complete
    final canSwipe = onSwipeComplete != null && status != 'Complete';

    final card = Card(
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
              // Top row: Name + optional "Filtered" badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _visible('name')
                        ? Text(
                            title,
                            style: Theme.of(context).textTheme.labelLarge,
                            softWrap: true,
                            // maxLines: 1,
                            // overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),

              // Status badge
              if (_visible('status')) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context, status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusTextColor(context, status),
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

              // Target Date + Remaining Days
              ...() {
                final bool showTarget = _visible('targetDate') && formattedTarget != null;
                final bool showRemaining = _visible('remainingDays') && remainingDays != null;

                if (!(showTarget || showRemaining)) return <Widget>[];

                final metaWidgets = <Widget>[];

                if (showTarget) {
                  metaWidgets.add(Text(
                    'Target: $formattedTarget',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ));
                }

                if (showRemaining) {
                  final rd = remainingDays!;
                  metaWidgets.add(Text(
                    rd >= 0
                        ? '$rd day${rd == 1 ? '' : 's'} left'
                        : 'Overdue by ${rd.abs()} day${rd.abs() == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: rd >= 0 ? cs.primary : cs.error,
                      fontWeight: FontWeight.w600,
                    ),
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
            ],
          ),
        ),
      ),
    );

    // Wrap in Dismissible if swipe is enabled
    if (canSwipe) {
      return Dismissible(
        key: Key('task_$id'),
        direction: DismissDirection.startToEnd, // Swipe right (startToEnd means swipe from left to right)
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Icon(
            Icons.check_circle,
            color: cs.onTertiaryContainer,
            size: 32,
          ),
        ),
        confirmDismiss: (_) async {
          // Call the callback to mark as complete
          onSwipeComplete?.call();
          // Return false to prevent the item from being dismissed
          // The status update will cause a rebuild with the new status
          return false;
        },
        child: card,
      );
    }

    return card;
  }
}

