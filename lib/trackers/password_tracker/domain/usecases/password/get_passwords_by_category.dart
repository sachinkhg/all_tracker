/*
  purpose:
    - Encapsulates the "Get Passwords By Category" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving [Password] entities
      filtered by category via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when passwords need to be filtered by category.
    - Returns a list of passwords matching the specified category.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/password.dart';
import '../../repositories/password_repository.dart';

/// Use case class responsible for retrieving [Password] entities by category.
class GetPasswordsByCategory {
  final PasswordRepository repository;
  GetPasswordsByCategory(this.repository);

  /// Executes the get by category operation asynchronously.
  Future<List<Password>> call(String categoryGroup) async => repository.getPasswordsByCategory(categoryGroup);
}

