import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_category.dart';

/// Base state for expense category operations
abstract class ExpenseCategoryState extends Equatable {
  const ExpenseCategoryState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class ExpenseCategoriesLoading extends ExpenseCategoryState {}

/// Loaded state
class ExpenseCategoriesLoaded extends ExpenseCategoryState {
  final List<ExpenseCategory> categories;

  const ExpenseCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Error state
class ExpenseCategoriesError extends ExpenseCategoryState {
  final String message;

  const ExpenseCategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

