import 'package:hive/hive.dart';
import '../models/habit_model.dart';

/// Abstract class defining the contract for habit local data operations.
///
/// This interface abstracts the data source implementation, allowing for
/// easy testing and potential future changes to the storage mechanism.
abstract class HabitLocalDataSource {
  /// Retrieves all habits from local storage.
  Future<List<HabitModel>> getAllHabits();

  /// Retrieves a specific habit by its ID.
  Future<HabitModel?> getHabitById(String id);

  /// Retrieves all habits associated with a specific milestone.
  Future<List<HabitModel>> getHabitsByMilestoneId(String milestoneId);

  /// Creates a new habit in local storage.
  Future<void> createHabit(HabitModel habit);

  /// Updates an existing habit in local storage.
  Future<void> updateHabit(HabitModel habit);

  /// Deletes a habit from local storage.
  Future<void> deleteHabit(String id);
}

/// Implementation of [HabitLocalDataSource] using Hive for local storage.
///
/// This class handles all CRUD operations for habits using a Hive box.
/// It provides a concrete implementation that can be easily tested and
/// potentially replaced with other storage mechanisms.
class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final Box<HabitModel> habitBox;

  HabitLocalDataSourceImpl({required this.habitBox});

  @override
  Future<List<HabitModel>> getAllHabits() async {
    try {
      return habitBox.values.toList();
    } catch (e) {
      throw Exception('Failed to retrieve habits: $e');
    }
  }

  @override
  Future<HabitModel?> getHabitById(String id) async {
    try {
      return habitBox.get(id);
    } catch (e) {
      throw Exception('Failed to retrieve habit with id $id: $e');
    }
  }

  @override
  Future<List<HabitModel>> getHabitsByMilestoneId(String milestoneId) async {
    try {
      return habitBox.values
          .where((habit) => habit.milestoneId == milestoneId)
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve habits for milestone $milestoneId: $e');
    }
  }

  @override
  Future<void> createHabit(HabitModel habit) async {
    try {
      await habitBox.put(habit.id, habit);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    try {
      await habitBox.put(habit.id, habit);
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    try {
      await habitBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete habit with id $id: $e');
    }
  }
}
