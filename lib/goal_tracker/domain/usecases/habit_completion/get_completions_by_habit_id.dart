import '../../entities/habit_completion.dart';
import '../../repositories/habit_completion_repository.dart';

/// Use case for retrieving completions for a specific habit.
///
/// This use case encapsulates the business logic for fetching habit
/// completions that belong to a particular habit. It provides a single
/// point of access for this operation and can be easily tested or modified.
class GetCompletionsByHabitId {
  final HabitCompletionRepository repository;

  GetCompletionsByHabitId({required this.repository});

  /// Retrieves all completions for the specified habit.
  Future<List<HabitCompletion>> call(String habitId) async {
    return await repository.getCompletionsByHabitId(habitId);
  }
}
