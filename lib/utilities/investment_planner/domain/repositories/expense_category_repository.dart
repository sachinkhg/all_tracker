/*
 * File: ./lib/utilities/investment_planner/domain/repositories/expense_category_repository.dart
 *
 * Purpose:
 *   Abstract repository interface for Expense Category operations.
 *   Defines the contract for persistence operations without implementation details.
 */

import '../entities/expense_category.dart';

/// Abstract repository interface for Expense Category operations.
abstract class ExpenseCategoryRepository {
  /// Creates a new expense category.
  Future<ExpenseCategory> createCategory(ExpenseCategory category);

  /// Retrieves all expense categories.
  Future<List<ExpenseCategory>> getAllCategories();

  /// Retrieves an expense category by ID.
  Future<ExpenseCategory?> getCategoryById(String id);

  /// Updates an existing expense category.
  Future<ExpenseCategory> updateCategory(ExpenseCategory category);

  /// Deletes an expense category by ID.
  Future<bool> deleteCategory(String id);
}

