/*
  purpose:
    - Encapsulates the "Search Books" use case in the domain layer.
    - Defines a single, testable action responsible for searching books
      via the Open Library API.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation layer when user searches for a book by title.
    - Returns a list of book search results that can be used to auto-fill form fields.

  compatibility guidance:
    - This use case depends on GoogleBooksDataSource, which is a data source abstraction.
    - Keep this use case simple and focused on the search operation.
*/

import '../../entities/book_search_result.dart';
import '../../../data/datasources/google_books_data_source.dart';

/// Use case class responsible for searching books by title.
class SearchBooks {
  final GoogleBooksDataSource dataSource;
  SearchBooks(this.dataSource);

  /// Executes the search operation asynchronously.
  ///
  /// Returns a list of [BookSearchResult] objects matching the query.
  /// Returns an empty list if no results are found or if an error occurs.
  Future<List<BookSearchResult>> call(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await dataSource.searchBooks(query);
  }
}

