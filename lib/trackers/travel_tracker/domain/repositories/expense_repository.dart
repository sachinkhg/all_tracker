import '../entities/expense.dart';

/// Abstract repository defining CRUD operations for [Expense] entities.
abstract class ExpenseRepository {
  /// Get all expenses for a trip.
  Future<List<Expense>> getExpensesByTripId(String tripId);

  /// Get expenses by date range for a trip.
  Future<List<Expense>> getExpensesByDateRange(String tripId, DateTime startDate, DateTime endDate);

  /// Get an expense by ID.
  Future<Expense?> getExpenseById(String id);

  /// Create a new expense.
  Future<void> createExpense(Expense expense);

  /// Update an existing expense.
  Future<void> updateExpense(Expense expense);

  /// Delete an expense.
  Future<void> deleteExpense(String id);
}

