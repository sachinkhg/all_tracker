// ./lib/utilities/investment_planner/domain/usecases/expense_category/get_all_expense_categories.dart
/*
  purpose:
    - Encapsulates the "Get All Expense Categories" domain use case.
*/

import '../../entities/expense_category.dart';
import '../../repositories/expense_category_repository.dart';

/// Use case class responsible for fetching all ExpenseCategory entities.
class GetAllExpenseCategories {
  final ExpenseCategoryRepository repository;

  GetAllExpenseCategories(this.repository);

  Future<List<ExpenseCategory>> call() async {
    return await repository.getAllCategories();
  }
}

