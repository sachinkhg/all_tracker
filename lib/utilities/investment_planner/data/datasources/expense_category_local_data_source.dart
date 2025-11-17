/*
 * File: expense_category_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Expense Category objects.
 */

import 'package:hive/hive.dart';
import '../models/expense_category_model.dart';

/// Abstract data source for local (Hive) expense category storage.
abstract class ExpenseCategoryLocalDataSource {
  Future<List<ExpenseCategoryModel>> getAllCategories();
  Future<ExpenseCategoryModel?> getCategoryById(String id);
  Future<void> createCategory(ExpenseCategoryModel category);
  Future<void> updateCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(String id);
}

/// Hive implementation of ExpenseCategoryLocalDataSource.
class ExpenseCategoryLocalDataSourceImpl
    implements ExpenseCategoryLocalDataSource {
  final Box<ExpenseCategoryModel> box;

  ExpenseCategoryLocalDataSourceImpl(this.box);

  @override
  Future<void> createCategory(ExpenseCategoryModel category) async {
    await box.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await box.delete(id);
  }

  @override
  Future<ExpenseCategoryModel?> getCategoryById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<ExpenseCategoryModel>> getAllCategories() async {
    return box.values.toList();
  }

  @override
  Future<void> updateCategory(ExpenseCategoryModel category) async {
    await box.put(category.id, category);
  }
}

