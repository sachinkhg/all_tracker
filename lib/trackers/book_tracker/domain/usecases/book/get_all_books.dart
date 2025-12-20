/*
  purpose:
    - Encapsulates the "Get All Books" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving all [Book] entities
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when books need to be loaded.
    - Returns a list of all books from storage.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/book.dart';
import '../../repositories/book_repository.dart';

/// Use case class responsible for retrieving all [Book] entities.
class GetAllBooks {
  final BookRepository repository;
  GetAllBooks(this.repository);

  /// Executes the get all operation asynchronously.
  Future<List<Book>> call() async => repository.getAllBooks();
}

