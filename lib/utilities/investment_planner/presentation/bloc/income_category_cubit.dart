import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/usecases/income_category/create_income_category.dart';
import '../../domain/usecases/income_category/get_all_income_categories.dart';
import '../../domain/usecases/income_category/update_income_category.dart';
import '../../domain/usecases/income_category/delete_income_category.dart';
import 'income_category_state.dart';

/// Cubit to manage IncomeCategory state
class IncomeCategoryCubit extends Cubit<IncomeCategoryState> {
  final GetAllIncomeCategories getAll;
  final CreateIncomeCategory create;
  final UpdateIncomeCategory update;
  final DeleteIncomeCategory delete;

  IncomeCategoryCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(IncomeCategoriesLoading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      emit(IncomeCategoriesLoading());
      final categories = await getAll();
      emit(IncomeCategoriesLoaded(categories));
    } catch (e) {
      emit(IncomeCategoriesError(e.toString()));
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final category = IncomeCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      );
      await create(category);
      await loadCategories();
    } catch (e) {
      emit(IncomeCategoriesError(e.toString()));
    }
  }

  Future<void> updateCategory(IncomeCategory category) async {
    try {
      await update(category);
      await loadCategories();
    } catch (e) {
      emit(IncomeCategoriesError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await delete(id);
      await loadCategories();
    } catch (e) {
      emit(IncomeCategoriesError(e.toString()));
    }
  }
}

