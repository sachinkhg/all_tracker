// lib/trackers/expense_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/expense_local_data_source.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../data/models/expense_model.dart';
import '../domain/usecases/expense/create_expense.dart';
import '../domain/usecases/expense/get_all_expenses.dart';
import '../domain/usecases/expense/get_expense_by_id.dart';
import '../domain/usecases/expense/get_expenses_by_group.dart';
import '../domain/usecases/expense/get_expenses_by_date_range.dart';
import '../domain/usecases/expense/get_expenses_by_group_and_date_range.dart';
import '../domain/usecases/expense/get_expense_insights.dart';
import '../domain/usecases/expense/update_expense.dart';
import '../domain/usecases/expense/delete_expense.dart';
import '../presentation/bloc/expense_cubit.dart';
import '../presentation/bloc/expense_insights_cubit.dart';
import 'constants.dart';

/// Factory that constructs a fully-wired [ExpenseCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
ExpenseCubit createExpenseCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(expenseTrackerBoxName)) {
    throw StateError(
      'Expense tracker box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<ExpenseModel> box = Hive.box<ExpenseModel>(expenseTrackerBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = ExpenseLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = ExpenseRepositoryImpl(local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllExpenses(repo);
  final getById = GetExpenseById(repo);
  final getByGroup = GetExpensesByGroup(repo);
  final getByDateRange = GetExpensesByDateRange(repo);
  final getByGroupAndDateRange = GetExpensesByGroupAndDateRange(repo);
  final create = CreateExpense(repo);
  final update = UpdateExpense(repo);
  final delete = DeleteExpense(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return ExpenseCubit(
    getAll: getAll,
    getById: getById,
    getByGroup: getByGroup,
    getByDateRange: getByDateRange,
    getByGroupAndDateRange: getByGroupAndDateRange,
    create: create,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired [ExpenseInsightsCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
ExpenseInsightsCubit createExpenseInsightsCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(expenseTrackerBoxName)) {
    throw StateError(
      'Expense tracker box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<ExpenseModel> box = Hive.box<ExpenseModel>(expenseTrackerBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = ExpenseLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = ExpenseRepositoryImpl(local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getInsights = GetExpenseInsights(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return ExpenseInsightsCubit(getInsights: getInsights);
}

