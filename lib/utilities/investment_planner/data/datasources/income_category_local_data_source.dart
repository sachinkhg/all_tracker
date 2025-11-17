/*
 * File: income_category_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Income Category objects.
 */

import 'package:hive/hive.dart';
import '../models/income_category_model.dart';

/// Abstract data source for local (Hive) income category storage.
abstract class IncomeCategoryLocalDataSource {
  Future<List<IncomeCategoryModel>> getAllCategories();
  Future<IncomeCategoryModel?> getCategoryById(String id);
  Future<void> createCategory(IncomeCategoryModel category);
  Future<void> updateCategory(IncomeCategoryModel category);
  Future<void> deleteCategory(String id);
}

/// Hive implementation of IncomeCategoryLocalDataSource.
class IncomeCategoryLocalDataSourceImpl
    implements IncomeCategoryLocalDataSource {
  final Box<IncomeCategoryModel> box;

  IncomeCategoryLocalDataSourceImpl(this.box);

  @override
  Future<void> createCategory(IncomeCategoryModel category) async {
    await box.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await box.delete(id);
  }

  @override
  Future<IncomeCategoryModel?> getCategoryById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<IncomeCategoryModel>> getAllCategories() async {
    return box.values.toList();
  }

  @override
  Future<void> updateCategory(IncomeCategoryModel category) async {
    await box.put(category.id, category);
  }
}

