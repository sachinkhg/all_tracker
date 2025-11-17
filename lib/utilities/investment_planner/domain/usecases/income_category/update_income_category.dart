// ./lib/utilities/investment_planner/domain/usecases/income_category/update_income_category.dart
/*
  purpose:
    - Encapsulates the "Update Income Category" use case in the domain layer.
*/

import '../../entities/income_category.dart';
import '../../repositories/income_category_repository.dart';

/// Use case class responsible for updating an existing IncomeCategory.
class UpdateIncomeCategory {
  final IncomeCategoryRepository repository;

  UpdateIncomeCategory(this.repository);

  Future<IncomeCategory> call(IncomeCategory category) async {
    return await repository.updateCategory(category);
  }
}

