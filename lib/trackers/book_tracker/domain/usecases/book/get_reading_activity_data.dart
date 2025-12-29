/*
  purpose:
    - Encapsulates the "Get Reading Activity Data" use case for chart visualization.
    - Aggregates books completed per month/year for timeline charts.
    - Filters data by optional date range.

  usage:
    - Invoked by analytics page to display reading activity timeline.
    - Returns time series data grouped by month/year.
*/

import '../../repositories/book_repository.dart';

/// Data point for reading activity timeline.
class ReadingActivityDataPoint {
  final DateTime month;
  final int bookCount;

  const ReadingActivityDataPoint({
    required this.month,
    required this.bookCount,
  });
}

/// Use case for getting reading activity data for charts.
class GetReadingActivityData {
  final BookRepository repository;

  GetReadingActivityData(this.repository);

  /// Get reading activity data grouped by month.
  /// 
  /// [startDate] and [endDate] are optional filters. If null, includes all data.
  /// Returns list of data points sorted by month (ascending).
  Future<List<ReadingActivityDataPoint>> call({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allBooks = await repository.getAllBooks();

    // Map to store month -> count
    final monthCounts = <DateTime, int>{};

    for (final book in allBooks) {
      // Check current read
      if (book.dateRead != null) {
        final readDate = book.dateRead!;
        if (_isInRange(readDate, startDate, endDate)) {
          final monthKey = DateTime(readDate.year, readDate.month);
          monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
        }
      }

      // Check read history
      for (final entry in book.readHistory) {
        if (entry.dateRead != null) {
          final readDate = entry.dateRead!;
          if (_isInRange(readDate, startDate, endDate)) {
            final monthKey = DateTime(readDate.year, readDate.month);
            monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
          }
        }
      }
    }

    // Convert to list and sort by month
    final dataPoints = monthCounts.entries
        .map((entry) => ReadingActivityDataPoint(
              month: entry.key,
              bookCount: entry.value,
            ))
        .toList();

    dataPoints.sort((a, b) => a.month.compareTo(b.month));

    return dataPoints;
  }

  bool _isInRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}

