import '../../entities/habit_completion.dart';
import '../../repositories/habit_completion_repository.dart';

/// Use case for retrieving completions within a date range.
///
/// This use case encapsulates the business logic for fetching habit
/// completions within a specific date range for a particular habit.
/// It provides a single point of access for this operation and can be
/// easily tested or modified.
class GetCompletionsByDateRange {
  final HabitCompletionRepository repository;

  GetCompletionsByDateRange({required this.repository});

  /// Retrieves completions for the specified habit within the date range.
  Future<List<HabitCompletion>> call(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await repository.getCompletionsByDateRange(
      habitId,
      startDate,
      endDate,
    );
  }
}
