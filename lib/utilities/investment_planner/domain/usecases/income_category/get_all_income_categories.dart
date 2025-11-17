// ./lib/utilities/investment_planner/domain/usecases/income_category/get_all_income_categories.dart
/*
  purpose:
    - Encapsulates the "Get All Income Categories" domain use case.
*/

import '../../entities/income_category.dart';
import '../../repositories/income_category_repository.dart';

/// Use case class responsible for fetching all IncomeCategory entities.
class GetAllIncomeCategories {
  final IncomeCategoryRepository repository;

  GetAllIncomeCategories(this.repository);

  Future<List<IncomeCategory>> call() async {
    return await repository.getAllCategories();
  }
}

