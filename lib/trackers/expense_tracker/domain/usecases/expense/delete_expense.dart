/*
  purpose:
    - Encapsulates the "Delete Expense" use case in the domain layer.
    - Defines a single, testable action responsible for deleting an [Expense]
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when an expense is deleted.
    - Accepts the expense ID to delete.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/expense_repository.dart';

/// Use case class responsible for deleting an [Expense].
class DeleteExpense {
  final ExpenseRepository repository;
  DeleteExpense(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteExpense(id);
}

