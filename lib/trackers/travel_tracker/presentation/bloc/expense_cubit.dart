import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/expense.dart';
import '../../core/constants.dart';
import '../../domain/usecases/expense/create_expense.dart';
import '../../domain/usecases/expense/get_expenses_by_trip_id.dart';
import '../../domain/usecases/expense/update_expense.dart';
import '../../domain/usecases/expense/delete_expense.dart';
import 'expense_state.dart';

/// Cubit to manage Expense state.
class ExpenseCubit extends Cubit<ExpenseState> {
  final CreateExpense create;
  final GetExpensesByTripId getExpenses;
  final UpdateExpense update;
  final DeleteExpense delete;

  static const _uuid = Uuid();

  ExpenseCubit({
    required this.create,
    required this.getExpenses,
    required this.update,
    required this.delete,
  }) : super(ExpensesLoading());

  Future<void> loadExpenses(String tripId) async {
    try {
      emit(ExpensesLoading());
      final expenses = await getExpenses(tripId);
      expenses.sort((a, b) => b.date.compareTo(a.date)); // Newest first
      emit(ExpensesLoaded(expenses));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> createExpenseEntry({
    required String tripId,
    required DateTime date,
    required ExpenseCategory category,
    required double amount,
    required String currency,
    String? description,
    String? paidBy,
  }) async {
    try {
      final now = DateTime.now();
      final expense = Expense(
        id: _uuid.v4(),
        tripId: tripId,
        date: date,
        category: category,
        amount: amount,
        currency: currency,
        description: description,
        paidBy: paidBy,
        createdAt: now,
        updatedAt: now,
      );

      await create(expense);
      await loadExpenses(tripId);
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> updateExpenseEntry(Expense expense) async {
    try {
      final updated = Expense(
        id: expense.id,
        tripId: expense.tripId,
        date: expense.date,
        category: expense.category,
        amount: expense.amount,
        currency: expense.currency,
        description: expense.description,
        paidBy: expense.paidBy,
        createdAt: expense.createdAt,
        updatedAt: DateTime.now(),
      );

      await update(updated);
      await loadExpenses(expense.tripId);
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> deleteExpenseEntry(String id, String tripId) async {
    try {
      await delete(id);
      await loadExpenses(tripId);
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }
}

