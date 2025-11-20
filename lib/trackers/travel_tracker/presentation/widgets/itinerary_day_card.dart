import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';

/// Widget displaying an itinerary day with its items.
class ItineraryDayCard extends StatelessWidget {
  final ItineraryDay day;
  final List<ItineraryItem> items;
  final VoidCallback onAddItem;
  final VoidCallback onEditDay;
  final Function(ItineraryItem) onEditItem;
  final Function(String) onDeleteItem;

  const ItineraryDayCard({
    super.key,
    required this.day,
    required this.items,
    required this.onAddItem,
    required this.onEditDay,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String formatTime(DateTime? time) {
      if (time == null) return '';
      return DateFormat('HH:mm').format(time);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(Icons.calendar_today, color: cs.primary),
        title: Text(
          DateFormat('MMM dd, yyyy').format(day.date),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: day.notes != null && day.notes!.isNotEmpty
            ? Text(day.notes!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAddItem,
              tooltip: 'Add Activity',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEditDay,
              tooltip: 'Edit Day',
            ),
          ],
        ),
        children: items.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No activities for this day',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ]
            : items.map((item) {
                return ListTile(
                  leading: Icon(
                    itineraryItemTypeIcons[item.type],
                    color: cs.primary,
                  ),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.time != null)
                        Text('Time: ${formatTime(item.time)}'),
                      if (item.location != null)
                        Text('Location: ${item.location}'),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Text(item.notes!),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.mapLink != null)
                        IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: () async {
                            final uri = Uri.parse(item.mapLink!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          tooltip: 'Open Map',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEditItem(item),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDeleteItem(item.id),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}

