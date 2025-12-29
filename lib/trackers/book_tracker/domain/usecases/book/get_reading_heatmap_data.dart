/*
  purpose:
    - Encapsulates the "Get Reading Heatmap Data" use case for calendar visualization.
    - Maps each day to the count of books completed on that day.
    - Filters data by optional date range.

  usage:
    - Invoked by analytics page to display calendar heatmap.
    - Returns map of dates to completion counts.
*/

import '../../repositories/book_repository.dart';

/// Use case for getting reading heatmap data for calendar.
class GetReadingHeatmapData {
  final BookRepository repository;

  GetReadingHeatmapData(this.repository);

  /// Get reading activity data mapped by day.
  /// 
  /// [startDate] and [endDate] are optional filters. If null, includes all data.
  /// Returns map where key is the date (time set to 00:00:00) and value is count.
  Future<Map<DateTime, int>> call({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allBooks = await repository.getAllBooks();

    // Map to store date -> count (date normalized to start of day)
    final dayCounts = <DateTime, int>{};

    for (final book in allBooks) {
      // Check current read
      if (book.dateRead != null) {
        final readDate = book.dateRead!;
        if (_isInRange(readDate, startDate, endDate)) {
          final dayKey = DateTime(readDate.year, readDate.month, readDate.day);
          dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
        }
      }

      // Check read history
      for (final entry in book.readHistory) {
        if (entry.dateRead != null) {
          final readDate = entry.dateRead!;
          if (_isInRange(readDate, startDate, endDate)) {
            final dayKey = DateTime(readDate.year, readDate.month, readDate.day);
            dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
          }
        }
      }
    }

    return dayCounts;
  }

  bool _isInRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}

