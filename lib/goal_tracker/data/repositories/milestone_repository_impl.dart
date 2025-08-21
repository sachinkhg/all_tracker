import 'package:uuid/uuid.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/milestone_repository.dart';
import '../datasources/milestone_local_data_source.dart';
import '../models/milestone_model.dart';
import '../models/task_model.dart';
import '../models/checklist_model.dart';

class MilestoneRepositoryImpl implements MilestoneRepository {
  final MilestoneLocalDataSource localDataSource;

  MilestoneRepositoryImpl(this.localDataSource);

  @override
  Future<List<Milestone>> getMilestones() async {
    final models = localDataSource.getMilestones();
    return models.map((m) => _mapModelToEntity(m)).toList();
  }

  @override
  Future<Milestone?> getMilestoneById(String id) async {
    final model = localDataSource.getMilestoneById(id);
    return model != null ? _mapModelToEntity(model) : null;
  }

  @override
  Future<void> addMilestone(Milestone milestone) async {
    final model = _mapEntityToModel(milestone);
    await localDataSource.addMilestone(model);
  }

  @override
  Future<void> updateMilestone(Milestone milestone) async {
    final model = _mapEntityToModel(milestone);
    await localDataSource.updateMilestone(model);
  }

  @override
  Future<void> deleteMilestone(String id) async {
    await localDataSource.deleteMilestone(id);
  }
  @override
  Future<void> clearAll() async {
    await localDataSource.clearAll();
  }

  // ------------------------
  // Mapping Helpers
  // ------------------------
  Milestone _mapModelToEntity(MilestoneModel model) {
    return Milestone(
      id: model.id,
      title: model.title,
      targetDate: model.targetDate,
      tasks: model.tasks.map((task) {
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
  }

  MilestoneModel _mapEntityToModel(Milestone entity) {
    return MilestoneModel(
      id: entity.id.isEmpty ? const Uuid().v4() : entity.id,
      title: entity.title,
      targetDate: entity.targetDate,
      tasks: entity.tasks.map((task) {
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
  }
}
