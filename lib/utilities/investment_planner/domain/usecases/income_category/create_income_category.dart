// ./lib/utilities/investment_planner/domain/usecases/income_category/create_income_category.dart
/*
  purpose:
    - Encapsulates the "Create Income Category" use case in the domain layer.
*/

import '../../entities/income_category.dart';
import '../../repositories/income_category_repository.dart';

/// Use case class responsible for creating a new IncomeCategory.
class CreateIncomeCategory {
  final IncomeCategoryRepository repository;

  CreateIncomeCategory(this.repository);

  Future<IncomeCategory> call(IncomeCategory category) async {
    return await repository.createCategory(category);
  }
}

