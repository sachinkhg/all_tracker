/*
  purpose:
    - Encapsulates the "Delete Book" use case in the domain layer.
    - Defines a single, testable action responsible for deleting a [Book]
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a book is deleted.
    - Accepts a book ID string.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/book_repository.dart';

/// Use case class responsible for deleting a [Book].
class DeleteBook {
  final BookRepository repository;
  DeleteBook(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteBook(id);
}

