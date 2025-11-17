import '../entities/habit_completion.dart';

/// Repository interface for HabitCompletion entities.
///
/// This abstract class defines the contract for habit completion data operations,
/// following the repository pattern used throughout the application.
abstract class HabitCompletionRepository {
  /// Retrieves all habit completions.
  Future<List<HabitCompletion>> getAllCompletions();

  /// Retrieves all completions for a specific habit.
  Future<List<HabitCompletion>> getCompletionsByHabitId(String habitId);

  /// Retrieves completions for a specific habit within a date range.
  Future<List<HabitCompletion>> getCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Creates a new habit completion.
  Future<void> createCompletion(HabitCompletion completion);

  /// Deletes a habit completion by its ID.
  Future<void> deleteCompletion(String id);

  /// Gets completion for a specific habit on a specific date.
  Future<HabitCompletion?> getCompletionForDate(String habitId, DateTime date);
}