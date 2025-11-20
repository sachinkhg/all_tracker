import '../../domain/entities/itinerary_item.dart';
import '../../domain/entities/journal_entry.dart';

/// Service for combining itinerary items and journal entries into a timeline.
class TimelineService {
  /// Combines itinerary items and journal entries into a single timeline sorted by time.
  static List<TimelineItem> combineAndSort({
    required List<ItineraryItem> items,
    required List<JournalEntry> entries,
  }) {
    final timelineItems = <TimelineItem>[];

    // Add itinerary items
    for (final item in items) {
      timelineItems.add(TimelineItem(
        type: TimelineItemType.itinerary,
        itineraryItem: item,
        time: item.time,
      ));
    }

    // Add journal entries
    for (final entry in entries) {
      timelineItems.add(TimelineItem(
        type: TimelineItemType.journal,
        journalEntry: entry,
        time: entry.date,
      ));
    }

    // Sort by time
    timelineItems.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return a.time!.compareTo(b.time!);
    });

    return timelineItems;
  }
}

/// Timeline item that can be either an itinerary item or journal entry.
class TimelineItem {
  final TimelineItemType type;
  final ItineraryItem? itineraryItem;
  final JournalEntry? journalEntry;
  final DateTime? time;

  TimelineItem({
    required this.type,
    this.itineraryItem,
    this.journalEntry,
    this.time,
  }) : assert(
          (type == TimelineItemType.itinerary && itineraryItem != null) ||
          (type == TimelineItemType.journal && journalEntry != null),
        );
}

enum TimelineItemType {
  itinerary,
  journal,
}

