import '../../entities/expense.dart';
import '../../repositories/expense_repository.dart';

/// Use case for updating an expense.
class UpdateExpense {
  final ExpenseRepository repository;

  UpdateExpense(this.repository);

  Future<void> call(Expense expense) async => repository.updateExpense(expense);
}

