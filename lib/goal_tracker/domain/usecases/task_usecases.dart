import '../entities/task.dart';
import '../repositories/task_repository.dart';

// ----------------------
// Get all Task
// ----------------------
class GetTasks {
  final TaskRepository repository;
  GetTasks(this.repository);

  Future<List<Task>> call() {
    return repository.getTasks();
  }
}

// ----------------------
// Get Task by ID
// ----------------------
class GetTaskById {
  final TaskRepository repository;
  GetTaskById(this.repository);

  Future<Task?> call(String id) {
    return repository.getTaskById(id);
  }
}

// ----------------------
// Add Task
// ----------------------
class AddTask {
  final TaskRepository repository;
  AddTask(this.repository);

  Future<void> call(Task task) {
    return repository.addTask(task);
  }
}

// ----------------------
// Update Task
// ----------------------
class UpdateTask {
  final TaskRepository repository;
  UpdateTask(this.repository);

  Future<void> call(Task task) {
    return repository.updateTask(task);
  }
}

// ----------------------
// Delete Task
// ----------------------
class DeleteTask {
  final TaskRepository repository;
  DeleteTask(this.repository);

  Future<void> call(String id) {
    return repository.deleteTask(id);
  }
}

// ----------------------
// Clear All Task
// ----------------------
class ClearAllTasks {
  final TaskRepository repository;
  ClearAllTasks(this.repository);

  Future<void> call() {
    return repository.clearAll();
  }
}

class GetTasksForMilestone {
  final TaskRepository repository;
  GetTasksForMilestone(this.repository);

  Future<List<Task>> call(String associatedMilestoneID) {
    return repository.getTasksForMilestone(associatedMilestoneID);
  }
}