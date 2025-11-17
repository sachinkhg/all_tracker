import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/usecases/expense_category/create_expense_category.dart';
import '../../domain/usecases/expense_category/get_all_expense_categories.dart';
import '../../domain/usecases/expense_category/update_expense_category.dart';
import '../../domain/usecases/expense_category/delete_expense_category.dart';
import 'expense_category_state.dart';

/// Cubit to manage ExpenseCategory state
class ExpenseCategoryCubit extends Cubit<ExpenseCategoryState> {
  final GetAllExpenseCategories getAll;
  final CreateExpenseCategory create;
  final UpdateExpenseCategory update;
  final DeleteExpenseCategory delete;

  ExpenseCategoryCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(ExpenseCategoriesLoading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      emit(ExpenseCategoriesLoading());
      final categories = await getAll();
      emit(ExpenseCategoriesLoaded(categories));
    } catch (e) {
      emit(ExpenseCategoriesError(e.toString()));
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final category = ExpenseCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      );
      await create(category);
      await loadCategories();
    } catch (e) {
      emit(ExpenseCategoriesError(e.toString()));
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    try {
      await update(category);
      await loadCategories();
    } catch (e) {
      emit(ExpenseCategoriesError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await delete(id);
      await loadCategories();
    } catch (e) {
      emit(ExpenseCategoriesError(e.toString()));
    }
  }
}

