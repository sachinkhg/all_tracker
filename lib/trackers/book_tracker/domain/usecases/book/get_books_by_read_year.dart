/*
  purpose:
    - Encapsulates the "Get Books By Read Year" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving books filtered by read year
      via the [BookRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when filtering by read year.
    - Returns a list of books where the latest dateRead falls in the specified year.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [BookRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/book.dart';
import '../../repositories/book_repository.dart';

/// Use case class responsible for retrieving books filtered by read year.
class GetBooksByReadYear {
  final BookRepository repository;
  GetBooksByReadYear(this.repository);

  /// Executes the get by read year operation asynchronously.
  Future<List<Book>> call(int year) async => repository.getBooksByReadYear(year);
}

