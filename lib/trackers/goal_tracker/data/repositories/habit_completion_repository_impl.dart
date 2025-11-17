import '../../domain/entities/habit_completion.dart';
import '../../domain/repositories/habit_completion_repository.dart';
import '../datasources/habit_completion_local_data_source.dart';
import '../models/habit_completion_model.dart';

/// Implementation of [HabitCompletionRepository] using local data source.
///
/// This class implements the habit completion repository interface by delegating
/// to a local data source and converting between domain entities and
/// data models. It acts as a bridge between the domain layer and the
/// data layer.
class HabitCompletionRepositoryImpl implements HabitCompletionRepository {
  final HabitCompletionLocalDataSource localDataSource;

  HabitCompletionRepositoryImpl({required this.localDataSource});

  @override
  Future<List<HabitCompletion>> getAllCompletions() async {
    try {
      final completionModels = await localDataSource.getAllCompletions();
      return completionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve all habit completions: $e');
    }
  }

  @override
  Future<List<HabitCompletion>> getCompletionsByHabitId(String habitId) async {
    try {
      final completionModels = await localDataSource.getCompletionsByHabitId(habitId);
      return completionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve completions for habit $habitId: $e');
    }
  }

  @override
  Future<List<HabitCompletion>> getCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final completionModels = await localDataSource.getCompletionsByHabitIdAndDateRange(
        habitId,
        startDate,
        endDate,
      );
      return completionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve completions for habit $habitId in date range: $e');
    }
  }

  @override
  Future<HabitCompletion?> getCompletionForDate(String habitId, DateTime date) async {
    try {
      final completionModel = await localDataSource.getCompletionForDate(habitId, date);
      return completionModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to retrieve completion for habit $habitId on date $date: $e');
    }
  }

  @override
  Future<void> createCompletion(HabitCompletion completion) async {
    try {
      final completionModel = HabitCompletionModel.fromEntity(completion);
      await localDataSource.createCompletion(completionModel);
    } catch (e) {
      throw Exception('Failed to create habit completion: $e');
    }
  }

  @override
  Future<void> deleteCompletion(String id) async {
    try {
      await localDataSource.deleteCompletion(id);
    } catch (e) {
      throw Exception('Failed to delete habit completion with id $id: $e');
    }
  }

  Future<void> deleteCompletionsByHabitId(String habitId) async {
    try {
      await localDataSource.deleteCompletionsByHabitId(habitId);
    } catch (e) {
      throw Exception('Failed to delete completions for habit $habitId: $e');
    }
  }
}
