import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/usecases/task_usecases.dart';

class TaskListState {
  final bool loading;
  final List<Task> tasks;
  final String? error;
  const TaskListState({this.loading = false, this.tasks = const [], this.error});

  TaskListState copyWith({bool? loading, List<Task>? tasks, String? error}) =>
      TaskListState(
        loading: loading ?? this.loading,
        tasks: tasks ?? this.tasks,
        error: error,
      );
}

class TaskListCubit extends Cubit<TaskListState> {
  final String milestoneId;
  final GetTasksForMilestone getTasksForMilestone;
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;

  TaskListCubit({
    required this.milestoneId,
    required this.getTasksForMilestone,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
  }) : super(const TaskListState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final tasks = await getTasksForMilestone(milestoneId);
      emit(state.copyWith(loading: false, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addOne(Task t) async { await addTask(t); await load(); }
  Future<void> updateOne(Task t) async { await updateTask(t); await load(); }
  Future<void> deleteOne(String id) async { await deleteTask(id); await load(); }
}
