/*
  purpose:
    - Encapsulates the "Get Page Count Distribution" use case for chart visualization.
    - Groups books by page count ranges for histogram display.
    - Filters data by optional date range based on when books were read.

  usage:
    - Invoked by analytics page to display page count distribution histogram.
    - Returns data points grouped by page count ranges.
*/

import '../../repositories/book_repository.dart';

/// Data point for page count distribution.
class PageCountRangeDataPoint {
  final String rangeLabel;
  final int bookCount;
  final int minPages;
  final int maxPages;

  const PageCountRangeDataPoint({
    required this.rangeLabel,
    required this.bookCount,
    required this.minPages,
    required this.maxPages,
  });
}

/// Use case for getting page count distribution data.
class GetPageCountDistribution {
  final BookRepository repository;

  GetPageCountDistribution(this.repository);

  /// Get page count distribution grouped into ranges.
  /// 
  /// [rangeSize] specifies the size of each range (default: 200 pages).
  /// [startDate] and [endDate] are optional filters based on read dates.
  /// Returns list of data points sorted by page count (ascending).
  Future<List<PageCountRangeDataPoint>> call({
    int rangeSize = 200,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allBooks = await repository.getAllBooks();

    // Map to store range -> count
    final rangeCounts = <int, int>{};

    for (final book in allBooks) {
      // Check if book was read in the date range
      bool wasReadInRange = false;

      // Check current read
      if (book.dateRead != null) {
        final readDate = book.dateRead!;
        if (_isInRange(readDate, startDate, endDate)) {
          wasReadInRange = true;
        }
      }

      // Check read history
      if (!wasReadInRange) {
        for (final entry in book.readHistory) {
          if (entry.dateRead != null) {
            final readDate = entry.dateRead!;
            if (_isInRange(readDate, startDate, endDate)) {
              wasReadInRange = true;
              break;
            }
          }
        }
      }

      // Count the book if it was read in the range (or no filter)
      if (wasReadInRange || (startDate == null && endDate == null)) {
        final pageCount = book.pageCount;
        final rangeIndex = (pageCount / rangeSize).floor();
        final rangeStart = rangeIndex * rangeSize;
        rangeCounts[rangeStart] = (rangeCounts[rangeStart] ?? 0) + 1;
      }
    }

    // Convert to list and sort by range start
    final dataPoints = rangeCounts.entries
        .map((entry) {
          final rangeStart = entry.key;
          final rangeEnd = rangeStart + rangeSize - 1;
          return PageCountRangeDataPoint(
            rangeLabel: '$rangeStart-$rangeEnd',
            bookCount: entry.value,
            minPages: rangeStart,
            maxPages: rangeEnd,
          );
        })
        .toList();

    dataPoints.sort((a, b) => a.minPages.compareTo(b.minPages));

    return dataPoints;
  }

  bool _isInRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}

