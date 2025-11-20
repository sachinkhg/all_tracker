import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_model.dart';

/// Concrete implementation of ExpenseRepository.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource local;

  ExpenseRepositoryImpl(this.local);

  @override
  Future<void> createExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await local.createExpense(model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await local.deleteExpense(id);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final model = await local.getExpenseById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Expense>> getExpensesByTripId(String tripId) async {
    final models = await local.getExpensesByTripId(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(String tripId, DateTime startDate, DateTime endDate) async {
    final models = await local.getExpensesByDateRange(tripId, startDate, endDate);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await local.updateExpense(model);
  }
}

