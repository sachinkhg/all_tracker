import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';
import '../../data/services/google_places_service.dart';

/// Widget displaying an itinerary day with its items.
class ItineraryDayCard extends StatefulWidget {
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
  State<ItineraryDayCard> createState() => _ItineraryDayCardState();
}

class _ItineraryDayCardState extends State<ItineraryDayCard> {
  bool _isExpanded = false;
  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String formatTime(DateTime? time) {
      if (time == null) return '';
      return DateFormat('HH:mm').format(time);
    }

    final hasActivities = widget.items.isNotEmpty;
    final canExpand = hasActivities;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header section (always visible)
          InkWell(
            onTap: canExpand
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(widget.day.date),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (widget.day.notes != null && widget.day.notes!.isNotEmpty)
                          Text(
                            widget.day.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        if (hasActivities)
                          Text(
                            '${widget.items.length} ${widget.items.length == 1 ? 'activity' : 'activities'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: widget.onAddItem,
                        tooltip: 'Add Activity',
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.note),
                            onPressed: widget.onEditDay,
                            tooltip: widget.day.notes != null && widget.day.notes!.isNotEmpty
                                ? 'Edit Day Notes'
                                : 'Add Day Notes',
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                widget.day.notes != null && widget.day.notes!.isNotEmpty
                                    ? Icons.edit
                                    : Icons.add,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (canExpand)
                        IconButton(
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Accordion content (only visible when expanded and has activities)
          if (_isExpanded && hasActivities)
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          if (_isExpanded && hasActivities)
            ...widget.items.map((item) {
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
                      InkWell(
                        onTap: () => _openLocationInMap(item.location!, item.mapLink),
                        child: Text(
                          'Location: ${item.location}',
                          style: TextStyle(
                            color: cs.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: cs.primary,
                          ),
                        ),
                      ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(item.notes!),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => widget.onEditItem(item),
                  tooltip: 'Edit',
                ),
              );
            }),
          // if (!hasActivities)
          //   Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Text(
          //       'No activities for this day',
          //       style: textTheme.bodyMedium?.copyWith(
          //         color: cs.onSurfaceVariant,
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Future<void> _openLocationInMap(String location, String? mapLink) async {
    try {
      String urlToOpen;
      
      // Prefer mapLink if available
      if (mapLink != null && mapLink.isNotEmpty) {
        urlToOpen = mapLink;
      } else {
        // Generate map link from location
        urlToOpen = _placesService.generateMapLink(location);
      }
      
      if (urlToOpen.isNotEmpty) {
        final uri = Uri.parse(urlToOpen);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error opening location in map: $e');
    }
  }
}

