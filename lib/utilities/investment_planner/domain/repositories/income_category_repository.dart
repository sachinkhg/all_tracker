/*
 * File: ./lib/utilities/investment_planner/domain/repositories/income_category_repository.dart
 *
 * Purpose:
 *   Abstract repository interface for Income Category operations.
 *   Defines the contract for persistence operations without implementation details.
 */

import '../entities/income_category.dart';

/// Abstract repository interface for Income Category operations.
abstract class IncomeCategoryRepository {
  /// Creates a new income category.
  Future<IncomeCategory> createCategory(IncomeCategory category);

  /// Retrieves all income categories.
  Future<List<IncomeCategory>> getAllCategories();

  /// Retrieves an income category by ID.
  Future<IncomeCategory?> getCategoryById(String id);

  /// Updates an existing income category.
  Future<IncomeCategory> updateCategory(IncomeCategory category);

  /// Deletes an income category by ID.
  Future<bool> deleteCategory(String id);
}

