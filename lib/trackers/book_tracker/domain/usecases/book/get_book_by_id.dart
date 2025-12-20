/*
  purpose:
    - Encapsulates the "Get Book By Id" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving a [Book] by its ID
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a specific book is needed.
    - Returns the book if found, null otherwise.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/book.dart';
import '../../repositories/book_repository.dart';

/// Use case class responsible for retrieving a [Book] by its ID.
class GetBookById {
  final BookRepository repository;
  GetBookById(this.repository);

  /// Executes the get by id operation asynchronously.
  Future<Book?> call(String id) async => repository.getBookById(id);
}

