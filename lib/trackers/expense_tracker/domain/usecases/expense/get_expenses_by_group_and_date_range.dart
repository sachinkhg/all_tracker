/*
  purpose:
    - Encapsulates the "Get Expenses By Group And Date Range" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving expenses filtered by both group and date range
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when expenses need to be filtered by both group and date range.
    - Returns a list of expenses matching the specified filters.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../entities/expense_group.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for retrieving expenses filtered by group and date range.
class GetExpensesByGroupAndDateRange {
  final ExpenseRepository repository;
  GetExpensesByGroupAndDateRange(this.repository);

  /// Executes the get by group and date range operation asynchronously.
  /// If [group] is null, filters only by date range.
  /// If [start] and [end] are null, filters only by group.
  /// If both are provided, applies both filters.
  /// If both are null, returns all expenses.
  Future<List<Expense>> call(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  ) async =>
      repository.getExpensesByGroupAndDateRange(group, start, end);
}

