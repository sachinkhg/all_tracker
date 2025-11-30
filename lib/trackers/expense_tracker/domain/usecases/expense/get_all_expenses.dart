/*
  purpose:
    - Encapsulates the "Get All Expenses" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving all [Expense] entities
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when expenses need to be loaded.
    - Returns a list of all expenses from storage.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for retrieving all [Expense] entities.
class GetAllExpenses {
  final ExpenseRepository repository;
  GetAllExpenses(this.repository);

  /// Executes the get all operation asynchronously.
  Future<List<Expense>> call() async => repository.getAllExpenses();
}

