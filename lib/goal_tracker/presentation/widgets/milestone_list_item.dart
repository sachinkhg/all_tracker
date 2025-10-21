import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// MilestoneListItem
///
/// File purpose:
/// - Represents a single milestone item displayed in a Milestone List view.
/// - Dynamically renders milestone attributes (name, description, planned/actual
///   values, target date, goal name, remaining days) based on the user's selected
///   visibility preferences.
/// - Acts as a presentation-layer widget only; it should not contain business
///   or persistence logic.
///
/// UI behavior and data mapping rules:
/// - Uses a flexible visibility configuration (`visibleFields`) to control
///   which milestone attributes are rendered.
/// - Each visibility key corresponds to a standardized presentation key:
///   'name', 'description', 'plannedValue', 'actualValue', 'targetDate',
///   'goalName', 'remainingDays'
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
class MilestoneListItem extends StatelessWidget {
  /// Unique milestone identifier — typically used for edit or navigation callbacks.
  final String id;

  /// Title / name of the milestone (required).
  final String title;

  /// Optional description of the milestone.
  final String? description;

  /// Optional planned numeric value (nullable).
  final double? plannedValue;

  /// Optional actual numeric value (nullable).
  final double? actualValue;

  /// Optional target date for the milestone.
  final DateTime? targetDate;

  /// Parent goal name (human-readable label).
  final String? goalName;

  /// Triggered when the user taps the item (usually opens the edit screen).
  final VoidCallback onEdit;

  /// Map of visibility flags that determines which fields are displayed.
  ///
  /// Expected keys:
  /// 'name', 'description', 'plannedValue', 'actualValue',
  /// 'targetDate', 'goalName', 'remainingDays'
  ///
  /// If `null`, defaults are:
  /// - name = true
  /// - description = true
  /// - others = false
  final Map<String, bool>? visibleFields;

  /// Whether the list is currently filtered. Used here for a small visual hint.
  final bool filterActive;

  const MilestoneListItem({
    super.key,
    required this.id,
    required this.title,
    this.description,
    this.plannedValue,
    this.actualValue,
    this.targetDate,
    this.goalName,
    required this.onEdit,
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
      // Default: name + description only
      return (key == 'name' || key == 'description');
    }
    return visibleFields![key] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final numberFmt = NumberFormat.compact();
    final dateFmt = DateFormat('dd MMM yyyy');

    final formattedTarget = targetDate != null ? dateFmt.format(targetDate!) : null;
    final plannedStr = plannedValue != null ? numberFmt.format(plannedValue) : null;
    final actualStr = actualValue != null ? numberFmt.format(actualValue) : null;

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
                  if (filterActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primaryContainer.withOpacity(0.28)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt, size: 14, color: cs.onPrimaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'Filtered',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Goal name badge (instead of goalId)
              if (_visible('goalName') && goalName != null && goalName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    goalName!,
                    style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Description
              if (_visible('description') && description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  softWrap: true,
                  // maxLines: 2,
                  // overflow: TextOverflow.ellipsis,
                ),
              ],

              // Planned / Actual values + Target Date + Remaining Days
              ...() {
                final bool showPlanned = _visible('plannedValue') && plannedStr != null;
                final bool showActual = _visible('actualValue') && actualStr != null;
                final bool showTarget = _visible('targetDate') && formattedTarget != null;
                final bool showRemaining = _visible('remainingDays') && remainingDays != null;

                if (!(showPlanned || showActual || showTarget || showRemaining)) return <Widget>[];

                final valueWidgets = <Widget>[];

                if (showPlanned) {
                  valueWidgets.add(Row(
                    children: [
                      Text('Planned: ', style: Theme.of(context).textTheme.bodySmall),
                      Text(plannedStr!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ));
                }

                if (showActual) {
                  if (valueWidgets.isNotEmpty) valueWidgets.add(const SizedBox(width: 12));
                  valueWidgets.add(Row(
                    children: [
                      Text('Actual: ', style: Theme.of(context).textTheme.bodySmall),
                      Text(actualStr!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ));
                }

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
                  if (valueWidgets.isNotEmpty) Row(children: valueWidgets),
                  if (metaWidgets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: metaWidgets.map((w) => Expanded(child: w)).toList(),
                    ),
                  ],
                ];
              }(),
            ],
          ),
        ),
      ),
    );
  }
}
