import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl(this.localDataSource);

  @override
  Future<List<Task>> getTasks() async {
    final models = localDataSource.getTasks();
    return models.map((m) => _mapModelToEntity(m)).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final model = localDataSource.getTaskById(id);
    return model != null ? _mapModelToEntity(model) : null;
  }

  @override
  Future<void> addTask(Task task) async {
    final model = _mapEntityToModel(task);
    await localDataSource.addTask(model);
  }

  @override
  Future<void> updateTask(Task task) async {
    final model = _mapEntityToModel(task);
    await localDataSource.updateTask(model);
  }

  @override
  Future<void> deleteTask(String id) async {
    await localDataSource.deleteTask(id);
  }
  @override
  Future<void> clearAll() async {
    await localDataSource.clearAll();
  }

  @override
  Future<List<Task>> getTasksForMilestone(String associatedMilestoneID) async {
    final models = localDataSource.getTasksForMilestone(associatedMilestoneID);
    return models.map((m) => _mapModelToEntity(m)).toList();
  }

  // ------------------------
  // Mapping Helpers
  // ------------------------
  Task _mapModelToEntity(TaskModel model) {
    return Task(
      id: model.id,
      name: model.name,
      dueDate: model.dueDate,
      associatedMilestoneId: model.associatedMilestoneId
    );
  }

  TaskModel _mapEntityToModel(Task entity) {
    return TaskModel(
      id: entity.id.isEmpty ? const Uuid().v4() : entity.id,
      name: entity.name,
      dueDate: entity.dueDate,
      associatedMilestoneId: entity.associatedMilestoneId,
    );
  }
}
