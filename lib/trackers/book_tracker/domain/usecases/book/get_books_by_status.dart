/*
  purpose:
    - Encapsulates the "Get Books By Status" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving books filtered by status
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when filtering by status.
    - Returns a list of books matching the specified status.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/book.dart';
import '../../entities/book_status.dart';
import '../../repositories/book_repository.dart';

/// Use case class responsible for retrieving books filtered by status.
class GetBooksByStatus {
  final BookRepository repository;
  GetBooksByStatus(this.repository);

  /// Executes the get by status operation asynchronously.
  Future<List<Book>> call(BookStatus status) async => repository.getBooksByStatus(status);
}

