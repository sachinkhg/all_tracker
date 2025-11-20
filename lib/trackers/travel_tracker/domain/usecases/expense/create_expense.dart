import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case for creating an expense.
class CreateExpense {
  final ExpenseRepository repository;

  CreateExpense(this.repository);

  Future<void> call(Expense expense) async => repository.createExpense(expense);
}

