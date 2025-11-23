import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/trip.dart';
import '../../core/app_icons.dart';
import '../../core/constants.dart';

/// Widget displaying a single trip item in the list.
class TripListItem extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final Map<String, bool>? visibleFields;

  const TripListItem({
    super.key,
    required this.trip,
    required this.onTap,
    this.visibleFields,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String formatDate(DateTime? date) {
      if (date == null) return '';
      return DateFormat('MMM dd, yyyy').format(date);
    }

    String dateRange() {
      if (trip.startDate == null && trip.endDate == null) {
        return 'No dates set';
      }
      if (trip.startDate != null && trip.endDate != null) {
        return '${formatDate(trip.startDate)} - ${formatDate(trip.endDate)}';
      }
      if (trip.startDate != null) {
        return 'From ${formatDate(trip.startDate)}';
      }
      return 'Until ${formatDate(trip.endDate)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    TravelTrackerIcons.trip,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trip.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (trip.tripType != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tripTypeIcons[trip.tripType]!,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tripTypeLabels[trip.tripType]!,
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
              if (trip.destination != null && (visibleFields?['destination'] ?? true)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.destination!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateRange(),
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (visibleFields?['description'] ?? false) ...[
                if (trip.description != null && trip.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    trip.description!,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

