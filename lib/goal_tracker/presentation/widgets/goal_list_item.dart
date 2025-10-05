import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalListItem extends StatelessWidget {
  final String id;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final String? contextValue;
  final VoidCallback onEdit;

  /// Map of visibility flags. Expected keys:
  /// 'name', 'description', 'targetDate', 'context', 'remainingDays'
  /// If null, defaults: name=true, description=true, others=false.
  final Map<String, bool>? visibleFields;

  const GoalListItem({
    super.key,
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    this.contextValue,
    required this.onEdit,
    this.visibleFields,
  });

  int? get remainingDays {
    if (targetDate == null) return null;
    final today = DateTime.now();
    return targetDate!.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  bool _visible(String key) {
    if (visibleFields == null) {
      // default behaviour: name & description visible
      return (key == 'name' || key == 'description');
    }
    return visibleFields![key] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              // Title (only shown when 'name' visible)
              if (_visible('name')) ...[
                Text(title, style: Theme.of(context).textTheme.labelLarge),
              ],

              // Optional: Context badge
              if (_visible('context') &&
                  contextValue != null &&
                  contextValue!.isNotEmpty) ...[
                const SizedBox(height: 4),
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

              // Optional: Description
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Optional: Target Date and Remaining Days
              if (_visible('targetDate') && targetDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: $formattedTarget',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (_visible('remainingDays') && remainingDays != null)
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
