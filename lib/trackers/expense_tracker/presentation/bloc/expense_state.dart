import 'package:equatable/equatable.dart';
import '../../domain/entities/expense.dart';

/// ---------------------------------------------------------------------------
/// ExpenseState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [ExpenseCubit] for managing expense
///   lifecycle and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [ExpensesLoading]: Emitted while loading expenses from the data source.
/// - [ExpensesLoaded]: Emitted when expenses are successfully loaded; contains a list
///   of [Expense] entities.
/// - [ExpensesError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [ExpenseState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

// Base state for expense operations
abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when expense data is being fetched.
class ExpensesLoading extends ExpenseState {}

// Loaded state — holds the list of successfully fetched expenses.
class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;

  const ExpensesLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

// Error state — emitted when fetching or modifying expenses fails.
class ExpensesError extends ExpenseState {
  final String message;

  const ExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}

