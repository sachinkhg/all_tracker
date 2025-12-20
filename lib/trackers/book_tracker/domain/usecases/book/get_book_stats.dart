/*
  purpose:
    - Encapsulates the "Get Book Stats" use case in the domain layer.
    - Defines a single, testable action responsible for calculating book statistics
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when statistics are needed.
    - Returns aggregated statistics about books.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/book_repository.dart';

/// Statistics data class for book tracking.
class BookStats {
  final int totalBooks;
  final int completedBooks;
  final int totalReads;
  final int totalPagesRead;
  final double? averageRating;

  const BookStats({
    required this.totalBooks,
    required this.completedBooks,
    required this.totalReads,
    required this.totalPagesRead,
    this.averageRating,
  });
}

/// Use case class responsible for calculating book statistics.
class GetBookStats {
  final BookRepository repository;
  GetBookStats(this.repository);

  /// Executes the stats calculation operation asynchronously.
  Future<BookStats> call() async {
    final allBooks = await repository.getAllBooks();

    final totalBooks = allBooks.length;

    // Count completed books (unique titles with dateRead or completed readHistory entries)
    final completedBooks = allBooks.where((book) {
      return book.dateRead != null ||
          book.readHistory.any((entry) => entry.isCompleted);
    }).length;

    // Count total reads (completed entries in readHistory + current completed reads)
    int totalReads = 0;
    int totalPagesRead = 0;
    double? sumRatings;
    int completedBooksWithRating = 0;

    for (final book in allBooks) {
      final completedReads = book.totalCompletedReads;
      if (completedReads > 0) {
        totalReads += completedReads;
        totalPagesRead += book.pageCount * completedReads;

        // Calculate average rating only for completed books
        if (book.avgRating != null && book.dateRead != null) {
          if (sumRatings == null) {
            sumRatings = 0.0;
          }
          sumRatings += book.avgRating!;
          completedBooksWithRating++;
        }
      }
    }

    final averageRating = completedBooksWithRating > 0 && sumRatings != null
        ? sumRatings / completedBooksWithRating
        : null;

    return BookStats(
      totalBooks: totalBooks,
      completedBooks: completedBooks,
      totalReads: totalReads,
      totalPagesRead: totalPagesRead,
      averageRating: averageRating,
    );
  }
}

