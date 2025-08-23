import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/task_usecases.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks getTasks;
  final GetTaskById getTaskById;
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final ClearAllTasks clearAllTasks;
  final GetTasksForMilestone getTasksForMilestone;

  // Track the "active" milestone for context-aware refreshes
  String? _currentMilestoneId;

  TaskBloc({
    required this.getTasks,
    required this.getTaskById,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
    required this.clearAllTasks,
    required this.getTasksForMilestone,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksForMilestone>(_onLoadTasksForMilestone); // <-- NEW
    on<GetTaskDetails>(_onGetTaskDetails);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ClearAllTasksEvent>(_onClearAllTasks);
    on<LoadTasksForMilestone>(_onLoadTasksForMilestone);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    _currentMilestoneId = null; // global view
    emit(TaskLoading());
    try {
      final tasks = await getTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onLoadTasksForMilestone(
    LoadTasksForMilestone event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await getTasksForMilestone(event.milestoneId);
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onGetTaskDetails(
      GetTaskDetails event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final task = await getTaskById(event.id);
      emit(TaskDetailsLoaded(task));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await addTask(event.task);
      _refreshAccordingToContext();
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(
      UpdateTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await updateTask(event.task);
      _refreshAccordingToContext();
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(
      DeleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await deleteTask(event.id);
      _refreshAccordingToContext();
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onClearAllTasks(
      ClearAllTasksEvent event, Emitter<TaskState> emit) async {
    try {
      await clearAllTasks();
      _refreshAccordingToContext();
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  // Helper: reload based on whether a milestone is active
  void _refreshAccordingToContext() {
    final id = _currentMilestoneId;
    if (id != null && id.isNotEmpty) {
      add(LoadTasksForMilestone(id));
    } else {
      add(LoadTasks());
    }
  }
}
