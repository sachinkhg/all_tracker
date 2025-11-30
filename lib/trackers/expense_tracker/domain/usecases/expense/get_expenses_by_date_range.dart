/*
  purpose:
    - Encapsulates the "Get Expenses By Date Range" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving expenses within a date range
      via the [ExpenseRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when expenses need to be filtered by date range.
    - Returns a list of expenses within the specified date range.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case class responsible for retrieving expenses within a date range.
class GetExpensesByDateRange {
  final ExpenseRepository repository;
  GetExpensesByDateRange(this.repository);

  /// Executes the get by date range operation asynchronously.
  /// [start] and [end] are inclusive.
  Future<List<Expense>> call(DateTime start, DateTime end) async =>
      repository.getExpensesByDateRange(start, end);
}

