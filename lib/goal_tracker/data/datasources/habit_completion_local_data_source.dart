import 'package:hive/hive.dart';
import '../models/habit_completion_model.dart';

/// Abstract class defining the contract for habit completion local data operations.
///
/// This interface abstracts the data source implementation, allowing for
/// easy testing and potential future changes to the storage mechanism.
abstract class HabitCompletionLocalDataSource {
  /// Retrieves all habit completions from local storage.
  Future<List<HabitCompletionModel>> getAllCompletions();

  /// Retrieves all completions for a specific habit.
  Future<List<HabitCompletionModel>> getCompletionsByHabitId(String habitId);

  /// Retrieves completions for a habit within a specific date range.
  Future<List<HabitCompletionModel>> getCompletionsByHabitIdAndDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Retrieves a specific completion for a habit on a specific date.
  Future<HabitCompletionModel?> getCompletionForDate(String habitId, DateTime date);

  /// Creates a new habit completion in local storage.
  Future<void> createCompletion(HabitCompletionModel completion);

  /// Deletes a habit completion from local storage.
  Future<void> deleteCompletion(String id);

  /// Deletes all completions for a specific habit.
  Future<void> deleteCompletionsByHabitId(String habitId);
}

/// Implementation of [HabitCompletionLocalDataSource] using Hive for local storage.
///
/// This class handles all CRUD operations for habit completions using a Hive box.
/// It provides a concrete implementation that can be easily tested and
/// potentially replaced with other storage mechanisms.
class HabitCompletionLocalDataSourceImpl implements HabitCompletionLocalDataSource {
  final Box<HabitCompletionModel> completionBox;

  HabitCompletionLocalDataSourceImpl({required this.completionBox});

  @override
  Future<List<HabitCompletionModel>> getAllCompletions() async {
    try {
      return completionBox.values.toList();
    } catch (e) {
      throw Exception('Failed to retrieve habit completions: $e');
    }
  }

  @override
  Future<List<HabitCompletionModel>> getCompletionsByHabitId(String habitId) async {
    try {
      return completionBox.values
          .where((completion) => completion.habitId == habitId)
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve completions for habit $habitId: $e');
    }
  }

  @override
  Future<List<HabitCompletionModel>> getCompletionsByHabitIdAndDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Normalize dates to date-only for comparison
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      return completionBox.values
          .where((completion) {
            if (completion.habitId != habitId) return false;
            
            final completionDate = DateTime(
              completion.completionDate.year,
              completion.completionDate.month,
              completion.completionDate.day,
            );
            
            return completionDate.isAtSameMomentAs(start) ||
                   completionDate.isAtSameMomentAs(end) ||
                   (completionDate.isAfter(start) && completionDate.isBefore(end));
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve completions for habit $habitId in date range: $e');
    }
  }

  @override
  Future<HabitCompletionModel?> getCompletionForDate(String habitId, DateTime date) async {
    try {
      // Normalize date to date-only for comparison
      final targetDate = DateTime(date.year, date.month, date.day);
      
      return completionBox.values
          .where((completion) {
            if (completion.habitId != habitId) return false;
            
            final completionDate = DateTime(
              completion.completionDate.year,
              completion.completionDate.month,
              completion.completionDate.day,
            );
            
            return completionDate.isAtSameMomentAs(targetDate);
          })
          .firstOrNull;
    } catch (e) {
      throw Exception('Failed to retrieve completion for habit $habitId on date $date: $e');
    }
  }

  @override
  Future<void> createCompletion(HabitCompletionModel completion) async {
    try {
      await completionBox.put(completion.id, completion);
    } catch (e) {
      throw Exception('Failed to create habit completion: $e');
    }
  }

  @override
  Future<void> deleteCompletion(String id) async {
    try {
      await completionBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete habit completion with id $id: $e');
    }
  }

  @override
  Future<void> deleteCompletionsByHabitId(String habitId) async {
    try {
      final completionsToDelete = completionBox.values
          .where((completion) => completion.habitId == habitId)
          .map((completion) => completion.id)
          .toList();
      
      for (final id in completionsToDelete) {
        await completionBox.delete(id);
      }
    } catch (e) {
      throw Exception('Failed to delete completions for habit $habitId: $e');
    }
  }
}
