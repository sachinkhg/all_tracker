/*
  purpose:
    - Encapsulates the "Get Expenses By Group" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving expenses filtered by group
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when expenses need to be filtered by group.
    - Returns a list of expenses matching the specified group.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../entities/expense_group.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for retrieving expenses filtered by group.
class GetExpensesByGroup {
  final ExpenseRepository repository;
  GetExpensesByGroup(this.repository);

  /// Executes the get by group operation asynchronously.
  Future<List<Expense>> call(ExpenseGroup group) async => repository.getExpensesByGroup(group);
}

