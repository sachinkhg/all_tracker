// ./lib/utilities/investment_planner/domain/usecases/expense_category/create_expense_category.dart
/*
  purpose:
    - Encapsulates the "Create Expense Category" use case in the domain layer.
*/

import '../../entities/expense_category.dart';
import '../../repositories/expense_category_repository.dart';

/// Use case class responsible for creating a new ExpenseCategory.
class CreateExpenseCategory {
  final ExpenseCategoryRepository repository;

  CreateExpenseCategory(this.repository);

  Future<ExpenseCategory> call(ExpenseCategory category) async {
    return await repository.createCategory(category);
  }
}

