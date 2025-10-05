import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/usecases/get_all_goals.dart';
import '../../domain/usecases/create_goal.dart';
import '../../domain/usecases/update_goal.dart';
import '../../domain/usecases/delete_goal.dart';
import 'goal_state.dart';

// Cubit to manage Goal state
class GoalCubit extends Cubit<GoalState> {
  final GetAllGoals getAll;
  final CreateGoal create;
  final UpdateGoal update;
  final DeleteGoal delete;

  List<Goal> _allGoals = []; // master copy of all goals
  String? _currentContextFilter;
  String? _currentTargetDateFilter;
  String? _currentGrouping; // e.g. 'context' or null

  String? get currentContextFilter => _currentContextFilter;
  String? get currentTargetDateFilter => _currentTargetDateFilter;
  String? get currentGrouping => _currentGrouping;

  bool get hasActiveFilters =>
    (_currentContextFilter != null && _currentContextFilter!.isNotEmpty) ||
    (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) ||
    (_currentGrouping != null && _currentGrouping!.isNotEmpty);

  GoalCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(GoalsLoading());

  // Load all goals
  Future<void> loadGoals() async {
    try {
      emit(GoalsLoading());
      final data = await getAll();
      _allGoals = data;
      emit(GoalsLoaded(List.from(_allGoals)));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  // Apply filters and emit a filtered list
  void applyFilter({String? contextFilter, String? targetDateFilter}) {
    _currentContextFilter = contextFilter;
    _currentTargetDateFilter = targetDateFilter;

    final filtered = _filterGoals(_allGoals);
    emit(GoalsLoaded(filtered));
  }

  // Apply grouping
  void applyGrouping({required String groupBy}) {
    _currentGrouping = groupBy;
    print("🔎 Applying grouping by $groupBy");

    var filtered = _filterGoals(_allGoals);

    if (groupBy == 'context') {
      filtered.sort((a, b) {
        final aCtx = a.context ?? '';
        final bCtx = b.context ?? '';
        return aCtx.compareTo(bCtx);
      });
    }

    print("📊 Grouped goals count: ${filtered.length}");
    emit(GoalsLoaded(filtered));
  }

  // Optional: clear filters
  void clearFilters() {
    _currentContextFilter = null;
    _currentTargetDateFilter = null;
    _currentGrouping = null;
    emit(GoalsLoaded(List.from(_allGoals)));
  }

  // Internal: filtering logic
  List<Goal> _filterGoals(List<Goal> source) {
    final now = DateTime.now();

    return source.where((g) {
      // Context filter
      if (_currentContextFilter != null && _currentContextFilter!.isNotEmpty) {
        if ((g.context ?? '') != _currentContextFilter) {
          return false;
        }
      }

      // Target date filter
      if (_currentTargetDateFilter != null) {
        final tf = _currentTargetDateFilter!;
        final td = g.targetDate;
        if (td == null) {
          return false;
        }

        switch (tf) {
          case 'This Month':
            if (!(td.year == now.year && td.month == now.month)) return false;
            break;
          case 'This Year':
            if (td.year != now.year) return false;
            break;
          case 'Next Month':
            if (!(td.year == now.year && td.month == now.month + 1)) return false;
            break;
          case 'Next Year':
            if (td.year != now.year + 1) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  // Create a new goal
  Future<void> addGoal(String name, String description, DateTime? targetDate, String? context) async {
    final id = const Uuid().v4();
    final goal = Goal(
      id: id,
      name: name,
      description: description,
      targetDate: targetDate,
      context: context,
    );
    await create(goal);
    await loadGoals();
  }

  // Update an existing goal
  Future<void> editGoal(String id, String name, String description, DateTime? targetDate, String? context, bool isCompleted) async {
    final goal = Goal(
      id: id,
      name: name,
      description: description,
      targetDate: targetDate,
      context: context,
    );
    await update(goal);
    await loadGoals();
  }

  // Delete a goal
  Future<void> removeGoal(String id) async {
    await delete(id);
    await loadGoals();
  }
}
