import '../entities/habit.dart';

/// Repository interface for Habit entities.
///
/// This abstract class defines the contract for habit data operations,
/// following the repository pattern used throughout the application.
abstract class HabitRepository {
  /// Retrieves all habits.
  Future<List<Habit>> getAllHabits();

  /// Retrieves a habit by its ID.
  Future<Habit?> getHabitById(String id);

  /// Retrieves all habits associated with a specific milestone.
  Future<List<Habit>> getHabitsByMilestoneId(String milestoneId);

  /// Creates a new habit.
  Future<void> createHabit(Habit habit);

  /// Updates an existing habit.
  Future<void> updateHabit(Habit habit);

  /// Deletes a habit by its ID.
  Future<void> deleteHabit(String id);
}