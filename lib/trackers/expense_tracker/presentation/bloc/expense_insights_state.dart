import 'package:equatable/equatable.dart';
import '../../domain/usecases/expense/get_expense_insights.dart';

/// ---------------------------------------------------------------------------
/// ExpenseInsightsState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [ExpenseInsightsCubit] for managing
///   expense insights calculation and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [ExpenseInsightsLoading]: Emitted while calculating insights.
/// - [ExpenseInsightsLoaded]: Emitted when insights are successfully calculated.
/// - [ExpenseInsightsError]: Emitted when an exception or calculation failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// ---------------------------------------------------------------------------

// Base state for expense insights operations
abstract class ExpenseInsightsState extends Equatable {
  const ExpenseInsightsState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when insights are being calculated.
class ExpenseInsightsLoading extends ExpenseInsightsState {}

// Loaded state — holds the calculated insights.
class ExpenseInsightsLoaded extends ExpenseInsightsState {
  final ExpenseInsights insights;

  const ExpenseInsightsLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

// Error state — emitted when calculating insights fails.
class ExpenseInsightsError extends ExpenseInsightsState {
  final String message;

  const ExpenseInsightsError(this.message);

  @override
  List<Object?> get props => [message];
}

