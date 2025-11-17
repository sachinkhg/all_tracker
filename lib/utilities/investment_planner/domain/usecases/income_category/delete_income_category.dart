// ./lib/utilities/investment_planner/domain/usecases/income_category/delete_income_category.dart
/*
  purpose:
    - Encapsulates the "Delete Income Category" use case in the domain layer.
*/

import '../../repositories/income_category_repository.dart';

/// Use case class responsible for deleting an IncomeCategory.
class DeleteIncomeCategory {
  final IncomeCategoryRepository repository;

  DeleteIncomeCategory(this.repository);

  Future<bool> call(String id) async {
    return await repository.deleteCategory(id);
  }
}

