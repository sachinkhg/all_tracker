import '../../../domain/entities/task.dart';

abstract class TaskEvent {}

class LoadTasks extends TaskEvent {}

class LoadTasksForMilestone extends TaskEvent {
  final String milestoneId;
  LoadTasksForMilestone(this.milestoneId);
}

class GetTaskDetails extends TaskEvent {
  final String id;
  GetTaskDetails(this.id);
}

class AddTaskEvent extends TaskEvent {
  final Task task;
  AddTaskEvent(this.task);
}

class UpdateTaskEvent extends TaskEvent {
  final Task task;
  UpdateTaskEvent(this.task);
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  DeleteTaskEvent(this.id);
}

class ClearAllTasksEvent extends TaskEvent {}
