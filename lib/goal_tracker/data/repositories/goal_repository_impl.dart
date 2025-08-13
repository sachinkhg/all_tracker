import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_data_source.dart';
import '../models/goal_model.dart';
import '../models/milestone_model.dart';
import '../models/task_model.dart';
import '../models/checklist_model.dart';

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
      milestones: model.milestones.map((milestone) {
        return Milestone(
          id: milestone.id,
          title: milestone.title,
          tasks: milestone.tasks.map((task) {
            return Task(
              id: task.id,
              name: task.name,
              completed: task.completed,
              checklists: task.checklists.map((check) {
                return Checklist(
                  id: check.id,
                  title: check.title,
                  isCompleted: check.isCompleted,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  GoalModel _mapEntityToModel(Goal entity) {
    return GoalModel(
      id: entity.id.isEmpty ? const Uuid().v4() : entity.id,
      title: entity.title,
      description: entity.description,
      milestones: entity.milestones.map((milestone) {
        return MilestoneModel(
          id: milestone.id.isEmpty ? const Uuid().v4() : milestone.id,
          title: milestone.title,
          tasks: milestone.tasks.map((task) {
            return TaskModel(
              id: task.id.isEmpty ? const Uuid().v4() : task.id,
              name: task.name,
              completed: task.completed,
              checklists: task.checklists.map((check) {
                return ChecklistModel(
                  id: check.id.isEmpty ? const Uuid().v4() : check.id,
                  title: check.title,
                  isCompleted: check.isCompleted,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
