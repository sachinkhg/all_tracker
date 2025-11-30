/*
  purpose:
    - Encapsulates the "Get Expense By ID" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving a single [Expense]
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a specific expense is needed.
    - Returns the expense if found, null otherwise.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for retrieving a single [Expense] by ID.
class GetExpenseById {
  final ExpenseRepository repository;
  GetExpenseById(this.repository);

  /// Executes the get by ID operation asynchronously.
  Future<Expense?> call(String id) async => repository.getExpenseById(id);
}

