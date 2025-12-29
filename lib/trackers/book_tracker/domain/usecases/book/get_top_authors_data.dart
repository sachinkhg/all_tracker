/*
  purpose:
    - Encapsulates the "Get Top Authors Data" use case for chart visualization.
    - Counts books by author and returns top N authors.
    - Filters data by optional date range based on when books were read.

  usage:
    - Invoked by analytics page to display top authors bar chart.
    - Returns sorted list of authors with book counts.
*/

import '../../repositories/book_repository.dart';

/// Data point for top authors chart.
class TopAuthorDataPoint {
  final String author;
  final int bookCount;

  const TopAuthorDataPoint({
    required this.author,
    required this.bookCount,
  });
}

/// Use case for getting top authors data for charts.
class GetTopAuthorsData {
  final BookRepository repository;

  GetTopAuthorsData(this.repository);

  /// Get top authors by book count.
  /// 
  /// [limit] specifies how many top authors to return (default: 15).
  /// [startDate] and [endDate] are optional filters based on read dates.
  /// Returns list sorted by book count (descending).
  Future<List<TopAuthorDataPoint>> call({
    int limit = 15,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allBooks = await repository.getAllBooks();

    // Map to store author -> count
    final authorCounts = <String, int>{};

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
        final author = book.primaryAuthor;
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      }
    }

    // Convert to list, sort by count descending, and take top N
    final dataPoints = authorCounts.entries
        .map((entry) => TopAuthorDataPoint(
              author: entry.key,
              bookCount: entry.value,
            ))
        .toList();

    dataPoints.sort((a, b) => b.bookCount.compareTo(a.bookCount));

    return dataPoints.take(limit).toList();
  }

  bool _isInRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}

