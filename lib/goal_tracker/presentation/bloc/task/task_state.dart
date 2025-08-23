import '../../../domain/entities/task.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  TaskLoaded(this.tasks);
}

class TaskDetailsLoaded extends TaskState {
  final Task? task; // null if not found
  TaskDetailsLoaded(this.task);
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}
