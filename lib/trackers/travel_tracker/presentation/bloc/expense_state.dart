import 'package:equatable/equatable.dart';
import '../../domain/entities/expense.dart';

/// Base state for expense operations.
abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Loading state.
class ExpensesLoading extends ExpenseState {}

/// Loaded state with expenses.
class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;

  const ExpensesLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

/// Error state.
class ExpensesError extends ExpenseState {
  final String message;

  const ExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}

