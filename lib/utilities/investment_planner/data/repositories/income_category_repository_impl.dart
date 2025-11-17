/*
 * File: income_category_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (IncomeCategory entity)
 *    with the data layer (IncomeCategoryModel / Hive-backed datasource).
 */

import '../../domain/entities/income_category.dart';
import '../../domain/repositories/income_category_repository.dart';
import '../datasources/income_category_local_data_source.dart';
import '../models/income_category_model.dart';

/// Concrete implementation of IncomeCategoryRepository.
class IncomeCategoryRepositoryImpl implements IncomeCategoryRepository {
  final IncomeCategoryLocalDataSource local;

  IncomeCategoryRepositoryImpl(this.local);

  @override
  Future<IncomeCategory> createCategory(IncomeCategory category) async {
    final model = IncomeCategoryModel.fromEntity(category);
    await local.createCategory(model);
    return category;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    await local.deleteCategory(id);
    return true;
  }

  @override
  Future<List<IncomeCategory>> getAllCategories() async {
    final models = await local.getAllCategories();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<IncomeCategory?> getCategoryById(String id) async {
    final model = await local.getCategoryById(id);
    return model?.toEntity();
  }

  @override
  Future<IncomeCategory> updateCategory(IncomeCategory category) async {
    final model = IncomeCategoryModel.fromEntity(category);
    await local.updateCategory(model);
    return category;
  }
}

