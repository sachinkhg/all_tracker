/*
 * File: expense_repository_impl.dart
 *
 * Purpose:
 *   Concrete implementation of ExpenseRepository that uses ExpenseLocalDataSource
 *   for persistence. This class bridges the domain layer (entities) and data layer (models).
 *
 * Responsibilities:
 *   - Convert between domain entities (Expense) and data models (ExpenseModel)
 *   - Delegate persistence operations to ExpenseLocalDataSource
 *   - Handle any data layer specific logic (filtering, sorting, etc.)
 *
 * Developer notes:
 *   - This implementation is intentionally thin — most logic should be in use cases or the data source.
 *   - Conversion between Expense and ExpenseModel is handled by the model's fromEntity/toEntity methods.
 */

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_group.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_model.dart';

/// Concrete implementation of [ExpenseRepository] using Hive for persistence.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource dataSource;

  ExpenseRepositoryImpl(this.dataSource);

  @override
  Future<List<Expense>> getAllExpenses() async {
    final models = await dataSource.getAllExpenses();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final model = await dataSource.getExpenseById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Expense>> getExpensesByGroup(ExpenseGroup group) async {
    final models = await dataSource.getExpensesByGroup(group);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final models = await dataSource.getExpensesByDateRange(start, end);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByGroupAndDateRange(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  ) async {
    final models = await dataSource.getExpensesByGroupAndDateRange(group, start, end);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> createExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await dataSource.createExpense(model);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await dataSource.updateExpense(model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await dataSource.deleteExpense(id);
  }
}

