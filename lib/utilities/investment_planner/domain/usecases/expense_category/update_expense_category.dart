// ./lib/utilities/investment_planner/domain/usecases/expense_category/update_expense_category.dart
/*
  purpose:
    - Encapsulates the "Update Expense Category" use case in the domain layer.
*/

import '../../entities/expense_category.dart';
import '../../repositories/expense_category_repository.dart';

/// Use case class responsible for updating an existing ExpenseCategory.
class UpdateExpenseCategory {
  final ExpenseCategoryRepository repository;

  UpdateExpenseCategory(this.repository);

  Future<ExpenseCategory> call(ExpenseCategory category) async {
    return await repository.updateCategory(category);
  }
}

