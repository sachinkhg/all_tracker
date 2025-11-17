import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_data_source.dart';
import '../models/habit_model.dart';

/// Implementation of [HabitRepository] using local data source.
///
/// This class implements the habit repository interface by delegating
/// to a local data source and converting between domain entities and
/// data models. It acts as a bridge between the domain layer and the
/// data layer.
class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;

  HabitRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Habit>> getAllHabits() async {
    try {
      final habitModels = await localDataSource.getAllHabits();
      return habitModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve all habits: $e');
    }
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    try {
      final habitModel = await localDataSource.getHabitById(id);
      return habitModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to retrieve habit with id $id: $e');
    }
  }

  @override
  Future<List<Habit>> getHabitsByMilestoneId(String milestoneId) async {
    try {
      final habitModels = await localDataSource.getHabitsByMilestoneId(milestoneId);
      return habitModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve habits for milestone $milestoneId: $e');
    }
  }

  @override
  Future<void> createHabit(Habit habit) async {
    try {
      final habitModel = HabitModel.fromEntity(habit);
      await localDataSource.createHabit(habitModel);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    try {
      final habitModel = HabitModel.fromEntity(habit);
      await localDataSource.updateHabit(habitModel);
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    try {
      await localDataSource.deleteHabit(id);
    } catch (e) {
      throw Exception('Failed to delete habit with id $id: $e');
    }
  }
}
