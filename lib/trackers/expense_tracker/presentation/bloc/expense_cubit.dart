import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/expense/get_all_expenses.dart';
import '../../domain/usecases/expense/get_expense_by_id.dart';
import '../../domain/usecases/expense/get_expenses_by_group.dart';
import '../../domain/usecases/expense/get_expenses_by_date_range.dart';
import '../../domain/usecases/expense/get_expenses_by_group_and_date_range.dart';
import '../../domain/usecases/expense/create_expense.dart';
import '../../domain/usecases/expense/update_expense.dart';
import '../../domain/usecases/expense/delete_expense.dart';
import 'expense_state.dart';

/// ---------------------------------------------------------------------------
/// ExpenseCubit
///
/// File purpose:
/// - Manages presentation state for Expense entities within the Expense feature.
/// - Loads, creates, updates and deletes expenses by delegating
///   to domain use-cases.
/// - Holds an internal master copy (`_allExpenses`) and emits filtered/derived
///   views to the UI via ExpenseState.
///
/// Developer guidance:
/// - Keep domain validation and persistence in the use-cases/repository; this
///   cubit should orchestrate and transform results for UI consumption only.
/// ---------------------------------------------------------------------------

class ExpenseCubit extends Cubit<ExpenseState> {
  final GetAllExpenses getAll;
  final GetExpenseById getById;
  final GetExpensesByGroup getByGroup;
  final GetExpensesByDateRange getByDateRange;
  final GetExpensesByGroupAndDateRange getByGroupAndDateRange;
  final CreateExpense create;
  final UpdateExpense update;
  final DeleteExpense delete;

  // master copy of all expenses fetched from the domain layer.
  List<Expense> _allExpenses = [];

  ExpenseCubit({
    required this.getAll,
    required this.getById,
    required this.getByGroup,
    required this.getByDateRange,
    required this.getByGroupAndDateRange,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(ExpensesLoading());

  /// Loads all expenses from the repository.
  Future<void> loadExpenses() async {
    emit(ExpensesLoading());
    try {
      _allExpenses = await getAll();
      emit(ExpensesLoaded(_allExpenses));
    } catch (e) {
      emit(ExpensesError('Failed to load expenses: $e'));
    }
  }

  /// Gets an expense by its ID.
  Future<Expense?> getExpenseById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(ExpensesError('Failed to get expense: $e'));
      return null;
    }
  }

  /// Gets expenses by group.
  Future<List<Expense>> getExpensesByGroup(group) async {
    try {
      return await getByGroup(group);
    } catch (e) {
      emit(ExpensesError('Failed to get expenses by group: $e'));
      return [];
    }
  }

  /// Gets expenses by date range.
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      return await getByDateRange(start, end);
    } catch (e) {
      emit(ExpensesError('Failed to get expenses by date range: $e'));
      return [];
    }
  }

  /// Gets expenses by group and date range.
  Future<List<Expense>> getExpensesByGroupAndDateRange(
    group,
    DateTime? start,
    DateTime? end,
  ) async {
    try {
      return await getByGroupAndDateRange(group, start, end);
    } catch (e) {
      emit(ExpensesError('Failed to get expenses by group and date range: $e'));
      return [];
    }
  }

  /// Creates a new expense.
  Future<void> createExpense({
    required DateTime date,
    required String description,
    required double amount,
    required group,
  }) async {
    try {
      final now = DateTime.now();
      final newExpense = Expense(
        id: const Uuid().v4(),
        date: date,
        description: description,
        amount: amount,
        group: group,
        createdAt: now,
        updatedAt: now,
      );

      await create(newExpense);
      await loadExpenses(); // Reload to get updated list
    } catch (e) {
      emit(ExpensesError('Failed to create expense: $e'));
    }
  }

  /// Updates an existing expense.
  Future<void> updateExpense(Expense expense) async {
    try {
      final updatedExpense = expense.copyWith(
        updatedAt: DateTime.now(),
      );
      await update(updatedExpense);
      await loadExpenses(); // Reload to get updated list
    } catch (e) {
      emit(ExpensesError('Failed to update expense: $e'));
    }
  }

  /// Deletes an expense by its ID.
  Future<void> deleteExpense(String id) async {
    try {
      await delete(id);
      await loadExpenses(); // Reload to get updated list
    } catch (e) {
      emit(ExpensesError('Failed to delete expense: $e'));
    }
  }
}

