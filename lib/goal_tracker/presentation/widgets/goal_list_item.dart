import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// GoalListItem
///
/// File purpose:
/// - Represents a single goal item displayed in the Goal List view.
/// - Dynamically renders goal attributes (name, description, target date,
///   context, remaining days) based on the user's selected visibility
///   preferences.
/// - Acts as a presentation-layer widget only; it should not contain business
///   or persistence logic.
///
/// UI behavior and data mapping rules:
/// - Uses a flexible visibility configuration (`visibleFields`) to control
///   which goal attributes are rendered.
/// - Each visibility key corresponds to a standardized presentation key:
///   'name', 'description', 'targetDate', 'context', 'remainingDays'.
/// - When `visibleFields` is null, defaults are applied (name + description ON).
///
/// Compatibility guidance:
/// - If additional visibility fields are introduced, always maintain backward
///   compatibility by providing explicit defaults in `_visible()`.
/// - UI should gracefully handle null or missing values for optional fields.
/// - The model expects formatted text and date display only; all formatting
///   logic for new fields should stay consistent with this widget's style.
///
/// Developer notes:
/// - Avoid adding stateful behavior or persistence here; this is a
///   stateless, render-only widget.
/// - If connecting with new domain entities, map their properties externally
///   before passing them into this widget.
/// ---------------------------------------------------------------------------

class GoalListItem extends StatelessWidget {
  /// Unique goal identifier — typically used for edit or navigation callbacks.
  final String id;

  /// Title of the goal (always required, typically user-defined).
  final String title;

  /// Optional description of the goal.
  final String? description;

  /// Optional target date for the goal; used to compute `remainingDays`.
  final DateTime? targetDate;

  /// Optional contextual category or tag label.
  final String? contextValue;

  /// Number of open milestones associated with this goal.
  final int? openMilestoneCount;

  /// Total milestones associated with this goal.
  final int? totalMilestoneCount;

  /// Completion percentage (0-100) of milestones (calculated as completed / total).
  final double? milestoneCompletionPercent;

  /// Triggered when the user taps the item (usually opens the edit screen).
  final VoidCallback onEdit;

  /// Map of visibility flags that determines which fields are displayed.
  ///
  /// Expected keys:
  /// 'name', 'description', 'targetDate', 'context', 'remainingDays', 'milestoneSummary'
  ///
  /// If `null`, defaults are:
  /// - name = true
  /// - description = true
  /// - others = false
  final Map<String, bool>? visibleFields;

  /// Whether the list is currently filtered. This is computed once in the
  /// parent and passed down to avoid re-reading the cubit in item builders.
  /// Used here only for a small visual hint (a compact "Filtered" badge).
  final bool filterActive;

  const GoalListItem({
    super.key,
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    this.contextValue,
    this.openMilestoneCount,
    this.totalMilestoneCount,
    this.milestoneCompletionPercent,
    required this.onEdit,
    this.visibleFields,
    this.filterActive = false,
  });

  /// Returns the number of days remaining until the target date.
  ///
  /// Returns:
  /// - `null` if no target date exists.
  /// - Positive integer if target is in the future.
  /// - Negative integer if the goal is overdue.
  ///
  /// Calculation:
  /// Difference is computed using only the date portion (ignores time).
  int? get remainingDays {
    if (targetDate == null) return null;
    final today = DateTime.now();
    return targetDate!.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

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

  String _formatPercent(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Pre-format target date for consistent presentation.
    final formattedTarget = targetDate != null
        ? DateFormat('dd MMM yyyy').format(targetDate!)
        : null;

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
              // Top row: Name on left, optional Filter badge on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Name Field ---
                  Expanded(
                    child: _visible('name')
                        ? Text(title, style: Theme.of(context).textTheme.labelLarge)
                        : const SizedBox.shrink(),
                  ),

                ],
              ),

              // --- Context Badge ---
              // Renders contextual information like category/tag when enabled.
              if (_visible('context') &&
                  contextValue != null &&
                  contextValue!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    contextValue!,
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // --- Description ---
              // Displays multi-line description text if enabled and non-empty.
              if (_visible('description') &&
                  description != null &&
                  description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                  softWrap: true,
                  // maxLines: 2,
                  // overflow: TextOverflow.ellipsis,
                ),
              ],

              // --- Target Date & Remaining Days ---
              // Render either or both independently based on visibility flags.
              ...() {
                final bool showTarget = _visible('targetDate') && targetDate != null;
                final bool showRemaining = _visible('remainingDays') && remainingDays != null;
                if (!(showTarget || showRemaining)) return <Widget>[];
                return <Widget>[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showTarget)
                        Text(
                          'Target: $formattedTarget',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      if (showRemaining)
                        Text(
                          remainingDays! >= 0
                              ? '${remainingDays!} day${remainingDays == 1 ? '' : 's'} left'
                              : 'Overdue by ${remainingDays!.abs()} day${remainingDays!.abs() == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: remainingDays! >= 0 ? cs.primary : cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ];
              }(),

              // --- Milestone Summary ---
              if (_visible('milestoneSummary')) ...[
                const SizedBox(height: 8),
                Text(
                  () {
                    final open = openMilestoneCount ?? 0;
                    final total = totalMilestoneCount ?? 0;
                    final percent = milestoneCompletionPercent ??
                        (total == 0 ? 0 : ((total - open) / total) * 100);
                    return 'Total Milestone: $open/$total (${_formatPercent(percent)}%)';
                  }(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
