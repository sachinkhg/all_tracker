/*
  purpose:
    - Encapsulates the "Get Re-read Statistics" use case for chart visualization.
    - Counts books that have been re-read vs books read only once.
    - Filters data by optional date range based on when books were read.

  usage:
    - Invoked by analytics page to display re-reads pie chart.
    - Returns counts for first reads and re-reads.
*/

import '../../repositories/book_repository.dart';

/// Statistics for re-reads vs first reads.
class RereadStatistics {
  final int firstReads;
  final int rereads;

  const RereadStatistics({
    required this.firstReads,
    required this.rereads,
  });

  int get total => firstReads + rereads;
}

/// Use case for getting re-read statistics.
class GetRereadStatistics {
  final BookRepository repository;

  GetRereadStatistics(this.repository);

  /// Get re-read statistics.
  /// 
  /// [startDate] and [endDate] are optional filters based on read dates.
  /// Returns counts of first reads (books with no read history) vs re-reads.
  Future<RereadStatistics> call({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allBooks = await repository.getAllBooks();

    int firstReads = 0;
    int rereads = 0;

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
        if (book.readHistory.isEmpty) {
          firstReads++;
        } else {
          rereads++;
        }
      }
    }

    return RereadStatistics(
      firstReads: firstReads,
      rereads: rereads,
    );
  }

  bool _isInRange(DateTime date, DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}

