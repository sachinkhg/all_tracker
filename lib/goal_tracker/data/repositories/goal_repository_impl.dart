import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_data_source.dart';
import '../models/goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;

  GoalRepositoryImpl(this.localDataSource);

  @override
  Future<List<Goal>> getGoals() async {
    final models = localDataSource.getGoals();
    return models.map((m) => _mapModelToEntity(m)).toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final model = localDataSource.getGoalById(id);
    return model != null ? _mapModelToEntity(model) : null;
  }

  @override
  Future<void> addGoal(Goal goal) async {
    final model = _mapEntityToModel(goal);
    await localDataSource.addGoal(model);
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final model = _mapEntityToModel(goal);
    await localDataSource.updateGoal(model);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await localDataSource.deleteGoal(id);
  }

  @override
  Future<void> clearAll() async {
    await localDataSource.clearAll();
  }

  // ------------------------
  // Mapping Helpers
  // ------------------------
  Goal _mapModelToEntity(GoalModel model) {
    return Goal(
      id: model.id,
      title: model.title,
      description: model.description,
      targetDate: model.targetDate,
      // Instead of mapping milestones, map IDs only
      milestoneIds: model.milestoneIds,
      // You may optionally load milestones here from milestone box if needed (see note below)
    );
  }

  GoalModel _mapEntityToModel(Goal entity) {
    return GoalModel(
      id: entity.id.isEmpty ? const Uuid().v4() : entity.id,
      title: entity.title,
      description: entity.description,
      targetDate: entity.targetDate,
      // Save only milestone IDs, not full objects
      milestoneIds: entity.milestoneIds,
    );
  }
}