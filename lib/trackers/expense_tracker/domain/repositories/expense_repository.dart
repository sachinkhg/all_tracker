import '../entities/expense.dart';
import '../entities/expense_group.dart';

/// Abstract repository interface for expense operations.
///
/// This interface defines the contract for expense data access operations.
/// Implementations should handle persistence, filtering, and querying logic.
abstract class ExpenseRepository {
  /// Retrieves all expenses.
  ///
  /// Returns a list of all expenses in the repository.
  /// Returns an empty list if no expenses exist.
  Future<List<Expense>> getAllExpenses();

  /// Retrieves an expense by its unique identifier.
  ///
  /// Returns the expense if found, null otherwise.
  Future<Expense?> getExpenseById(String id);

  /// Retrieves expenses filtered by group.
  ///
  /// Returns all expenses that match the specified group.
  Future<List<Expense>> getExpensesByGroup(ExpenseGroup group);

  /// Retrieves expenses within a date range.
  ///
  /// Returns all expenses where the date is between [start] (inclusive) and [end] (inclusive).
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);

  /// Retrieves expenses filtered by group and date range.
  ///
  /// If [group] is null, filters only by date range.
  /// If [start] and [end] are null, filters only by group.
  /// If both are provided, applies both filters.
  /// If both are null, returns all expenses.
  Future<List<Expense>> getExpensesByGroupAndDateRange(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  );

  /// Creates a new expense.
  ///
  /// Throws an exception if the expense cannot be created.
  Future<void> createExpense(Expense expense);

  /// Updates an existing expense.
  ///
  /// Throws an exception if the expense does not exist or cannot be updated.
  Future<void> updateExpense(Expense expense);

  /// Deletes an expense by its unique identifier.
  ///
  /// Throws an exception if the expense does not exist or cannot be deleted.
  Future<void> deleteExpense(String id);
}

