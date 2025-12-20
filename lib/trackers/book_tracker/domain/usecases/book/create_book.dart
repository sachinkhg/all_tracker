/*
  purpose:
    - Encapsulates the "Create Book" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Book]
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new book is created.
    - Accepts a [Book] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/book.dart';
import '../../repositories/book_repository.dart';

/// Use case class responsible for creating a new [Book].
class CreateBook {
  final BookRepository repository;
  CreateBook(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(Book book) async => repository.createBook(book);
}

