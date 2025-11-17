// ./lib/utilities/investment_planner/domain/usecases/expense_category/delete_expense_category.dart
/*
  purpose:
    - Encapsulates the "Delete Expense Category" use case in the domain layer.
*/

import '../../repositories/expense_category_repository.dart';

/// Use case class responsible for deleting an ExpenseCategory.
class DeleteExpenseCategory {
  final ExpenseCategoryRepository repository;

  DeleteExpenseCategory(this.repository);

  Future<bool> call(String id) async {
    return await repository.deleteCategory(id);
  }
}

