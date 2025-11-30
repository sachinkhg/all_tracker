/*
  purpose:
    - Encapsulates the "Get Expense Insights" use case in the domain layer.
    - Defines a single, testable action responsible for calculating expense insights
      such as totals by group, percentages, transaction counts, etc.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when dashboard insights are needed.
    - Accepts optional filters (group and date range) and returns calculated insights.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [ExpenseRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/expense_group.dart';
import '../../repositories/expense_repository.dart';

/// Data class representing expense insights for dashboard display.
class ExpenseInsights {
  final double totalExpenses; // Sum of positive amounts (debits)
  final double totalCredits; // Sum of negative amounts (credits)
  final double netBalance; // totalCredits - totalExpenses
  final int transactionCount;
  final Map<ExpenseGroup, double> totalsByGroup; // Total amount per group
  final Map<ExpenseGroup, double> percentagesByGroup; // Percentage of total per group
  final Map<ExpenseGroup, int> countsByGroup; // Transaction count per group

  const ExpenseInsights({
    required this.totalExpenses,
    required this.totalCredits,
    required this.netBalance,
    required this.transactionCount,
    required this.totalsByGroup,
    required this.percentagesByGroup,
    required this.countsByGroup,
  });
}

/// Use case class responsible for calculating expense insights.
class GetExpenseInsights {
  final ExpenseRepository repository;
  GetExpenseInsights(this.repository);

  /// Calculates insights for expenses, optionally filtered by group and date range.
  ///
  /// If [group] is null, includes all groups.
  /// If [start] and [end] are null, includes all dates.
  Future<ExpenseInsights> call(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  ) async {
    final expenses = await repository.getExpensesByGroupAndDateRange(group, start, end);

    // Calculate totals
    double totalExpenses = 0.0;
    double totalCredits = 0.0;
    final totalsByGroup = <ExpenseGroup, double>{};
    final countsByGroup = <ExpenseGroup, int>{};

    for (final expense in expenses) {
      if (expense.amount > 0) {
        totalExpenses += expense.amount;
      } else {
        totalCredits += expense.amount.abs();
      }

      totalsByGroup[expense.group] = (totalsByGroup[expense.group] ?? 0.0) + expense.amount;
      countsByGroup[expense.group] = (countsByGroup[expense.group] ?? 0) + 1;
    }

    final netBalance = totalCredits - totalExpenses;
    final totalAmount = totalExpenses + totalCredits;

    // Calculate percentages
    final percentagesByGroup = <ExpenseGroup, double>{};
    for (final entry in totalsByGroup.entries) {
      if (totalAmount > 0) {
        percentagesByGroup[entry.key] = (entry.value.abs() / totalAmount) * 100;
      } else {
        percentagesByGroup[entry.key] = 0.0;
      }
    }

    return ExpenseInsights(
      totalExpenses: totalExpenses,
      totalCredits: totalCredits,
      netBalance: netBalance,
      transactionCount: expenses.length,
      totalsByGroup: totalsByGroup,
      percentagesByGroup: percentagesByGroup,
      countsByGroup: countsByGroup,
    );
  }
}

