import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import 'timeline_service.dart';

/// Widget displaying a single timeline item.
class TimelineItemWidget extends StatelessWidget {
  final TimelineItem item;

  const TimelineItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String formatTime(DateTime? time) {
      if (time == null) return '';
      return DateFormat('HH:mm').format(time);
    }

    if (item.type == TimelineItemType.itinerary) {
      final itineraryItem = item.itineraryItem!;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            itineraryItemTypeIcons[itineraryItem.type],
            color: cs.primary,
          ),
          title: Text(itineraryItem.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (itineraryItem.time != null)
                Text('Time: ${formatTime(itineraryItem.time)}'),
              if (itineraryItem.location != null)
                Text('Location: ${itineraryItem.location}'),
              if (itineraryItem.notes != null && itineraryItem.notes!.isNotEmpty)
                Text(itineraryItem.notes!),
            ],
          ),
          trailing: Text(
            itineraryItemTypeLabels[itineraryItem.type]!,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      final journalEntry = item.journalEntry!;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(Icons.book, color: cs.primary),
          title: Text(
            DateFormat('MMM dd, yyyy').format(journalEntry.date),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            journalEntry.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            formatTime(journalEntry.date),
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
  }
}

