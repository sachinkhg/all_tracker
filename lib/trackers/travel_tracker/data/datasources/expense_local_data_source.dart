import 'package:hive/hive.dart';
import '../models/expense_model.dart';

/// Abstract data source for local expense storage.
abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpensesByTripId(String tripId);
  Future<List<ExpenseModel>> getExpensesByDateRange(String tripId, DateTime startDate, DateTime endDate);
  Future<ExpenseModel?> getExpenseById(String id);
  Future<void> createExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

/// Hive implementation of ExpenseLocalDataSource.
class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final Box<ExpenseModel> box;

  ExpenseLocalDataSourceImpl(this.box);

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    await box.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await box.delete(id);
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<ExpenseModel>> getExpensesByTripId(String tripId) async {
    return box.values.where((expense) => expense.tripId == tripId).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(String tripId, DateTime startDate, DateTime endDate) async {
    return box.values.where((expense) {
      return expense.tripId == tripId &&
          expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await box.put(expense.id, expense);
  }
}

