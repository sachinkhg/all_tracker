/*
 * File: expense_category_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (ExpenseCategory entity)
 *    with the data layer (ExpenseCategoryModel / Hive-backed datasource).
 */

import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_category_repository.dart';
import '../datasources/expense_category_local_data_source.dart';
import '../models/expense_category_model.dart';

/// Concrete implementation of ExpenseCategoryRepository.
class ExpenseCategoryRepositoryImpl implements ExpenseCategoryRepository {
  final ExpenseCategoryLocalDataSource local;

  ExpenseCategoryRepositoryImpl(this.local);

  @override
  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    final model = ExpenseCategoryModel.fromEntity(category);
    await local.createCategory(model);
    return category;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    await local.deleteCategory(id);
    return true;
  }

  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    final models = await local.getAllCategories();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ExpenseCategory?> getCategoryById(String id) async {
    final model = await local.getCategoryById(id);
    return model?.toEntity();
  }

  @override
  Future<ExpenseCategory> updateCategory(ExpenseCategory category) async {
    final model = ExpenseCategoryModel.fromEntity(category);
    await local.updateCategory(model);
    return category;
  }
}

