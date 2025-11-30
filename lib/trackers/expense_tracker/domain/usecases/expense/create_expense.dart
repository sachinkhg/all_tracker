/*
  purpose:
    - Encapsulates the "Create Expense" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Expense]
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new expense is created.
    - Accepts an [Expense] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for creating a new [Expense].
class CreateExpense {
  final ExpenseRepository repository;
  CreateExpense(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(Expense expense) async => repository.createExpense(expense);
}

