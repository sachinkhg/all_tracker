/*
  purpose:
    - Encapsulates the "Update Expense" use case in the domain layer.
    - Defines a single, testable action responsible for updating an existing [Expense]
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when an expense is updated.
    - Accepts an [Expense] domain entity with updated fields.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for updating an existing [Expense].
class UpdateExpense {
  final ExpenseRepository repository;
  UpdateExpense(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(Expense expense) async => repository.updateExpense(expense);
}

