import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/expense_group.dart';
import '../../domain/usecases/expense/get_expense_insights.dart';
import 'expense_insights_state.dart';

/// ---------------------------------------------------------------------------
/// ExpenseInsightsCubit
///
/// File purpose:
/// - Manages presentation state for expense insights/analytics.
/// - Calculates insights (totals, percentages, counts) by delegating
///   to domain use-cases.
/// - Supports filtering by group and date range.
///
/// Developer guidance:
/// - Keep calculation logic in the use-case; this cubit should orchestrate
///   and transform results for UI consumption only.
/// ---------------------------------------------------------------------------

class ExpenseInsightsCubit extends Cubit<ExpenseInsightsState> {
  final GetExpenseInsights getInsights;

  ExpenseInsightsCubit({
    required this.getInsights,
  }) : super(ExpenseInsightsLoading());

  /// Loads insights for expenses, optionally filtered by group and date range.
  Future<void> loadInsights({
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  }) async {
    emit(ExpenseInsightsLoading());
    try {
      final insights = await getInsights(group, start, end);
      emit(ExpenseInsightsLoaded(insights));
    } catch (e) {
      emit(ExpenseInsightsError('Failed to load insights: $e'));
    }
  }
}

