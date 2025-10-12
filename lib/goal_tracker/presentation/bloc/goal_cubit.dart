import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/usecases/goal/get_all_goals.dart';
import '../../domain/usecases/goal/create_goal.dart';
import '../../domain/usecases/goal/update_goal.dart';
import '../../domain/usecases/goal/delete_goal.dart';
import 'goal_state.dart';

/// ---------------------------------------------------------------------------
/// GoalCubit
///
/// File purpose:
/// - Manages presentation state for Goal entities within the Goal feature.
/// - Loads, filters, groups, creates, updates and deletes goals by delegating
///   to domain use-cases (GetAllGoals, CreateGoal, UpdateGoal, DeleteGoal).
/// - Holds an internal master copy (`_allGoals`) and emits filtered/derived
///   views to the UI via GoalState.
///
/// State & behavior notes:
/// - This cubit keeps a simple in-memory master list (`_allGoals`) and applies
///   lightweight filtering/grouping in the presentation layer. For large
///   datasets or complex queries consider pushing filters into the repository
///   layer for efficiency.
/// - Filter and grouping keys are simple strings (e.g., 'context', 'This Month')
///   and should remain stable. If you change keys, update any persisted filter
///   storage and migration notes accordingly.
///
/// Developer guidance:
/// - Keep domain validation and persistence in the use-cases/repository; this
///   cubit should orchestrate and transform results for UI consumption only.
/// - Avoid adding heavy synchronous computation here; prefer async streams or
///   repository-side queries for scale.
/// ---------------------------------------------------------------------------

// Cubit to manage Goal state
class GoalCubit extends Cubit<GoalState> {
  final GetAllGoals getAll;
  final CreateGoal create;
  final UpdateGoal update;
  final DeleteGoal delete;

  // master copy of all goals fetched from the domain layer.
  List<Goal> _allGoals = []; // master copy of all goals
  String? _currentContextFilter;
  String? _currentTargetDateFilter;
  String? _currentGrouping; // e.g. 'context' or null

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = const {
    'name': true,
    'description': true,
    'targetDate': false,
    'context': false,
    'remainingDays': false,
  };

  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    // Re-emit current view to trigger UI rebuild with new visibility
    if (state is GoalsLoaded) {
      final current = state as GoalsLoaded;
      emit(GoalsLoaded(List<Goal>.from(current.goals), visibleFields));
    } else {
      emit(GoalsLoaded(List<Goal>.from(_allGoals), visibleFields));
    }
  }

  String? get currentContextFilter => _currentContextFilter;
  String? get currentTargetDateFilter => _currentTargetDateFilter;
  String? get currentGrouping => _currentGrouping;

  /// Returns true when any filter or grouping is active.
  bool get hasActiveFilters =>
      (_currentContextFilter != null && _currentContextFilter!.isNotEmpty) ||
      (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) ||
      (_currentGrouping != null && _currentGrouping!.isNotEmpty);

  /// Human-readable summary of active filters for UI consumption.
  ///
  /// Examples:
  ///  - "Context: Work • Date: This Month • Group: context"
  ///  - "Filters applied" (when hasActiveFilters is true but no specific fields are set)
  String get filterSummary {
    final parts = <String>[];

    if (_currentContextFilter != null && _currentContextFilter!.isNotEmpty) {
      parts.add('Context: ${_currentContextFilter!}');
    }
    if (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) {
      parts.add('Date: ${_currentTargetDateFilter!}');
    }
    if (_currentGrouping != null && _currentGrouping!.isNotEmpty) {
      parts.add('Group: ${_currentGrouping!}');
    }

    if (parts.isEmpty) {
      // If there are active filters (hasActiveFilters true) but no specific labels,
      // return a generic message. If no filters at all, caller usually won't show header.
      return 'Filters applied';
    }

    return parts.join(' • ');
  }

  GoalCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(GoalsLoading());

  Future<void> loadGoals() async {
    try {
      emit(GoalsLoading());
      final data = await getAll();
      _allGoals = data;
      emit(GoalsLoaded(List.from(_allGoals), visibleFields));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  void applyFilter({String? contextFilter, String? targetDateFilter}) {
    _currentContextFilter = contextFilter;
    _currentTargetDateFilter = targetDateFilter;

    final filtered = _filterGoals(_allGoals);
    emit(GoalsLoaded(filtered, visibleFields));
  }

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
    emit(GoalsLoaded(filtered, visibleFields));
  }

  void clearFilters() {
    _currentContextFilter = null;
    _currentTargetDateFilter = null;
    _currentGrouping = null;
    emit(GoalsLoaded(List.from(_allGoals), visibleFields));
  }

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

        final today = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(td.year, td.month, td.day);

        switch (tf) {
          case 'Today':
            if (targetDay != today) return false;
            break;
          case 'Tomorrow':
            final tomorrow = today.add(const Duration(days: 1));
            if (targetDay != tomorrow) return false;
            break;
          case 'This Week':
            final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            if (targetDay.isBefore(startOfWeek) || targetDay.isAfter(endOfWeek)) return false;
            break;
          case 'Next Week':
            final nextWeekStart = today.add(Duration(days: 8 - now.weekday));
            final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
            if (targetDay.isBefore(nextWeekStart) || targetDay.isAfter(nextWeekEnd)) return false;
            break;
          case 'This Month':
            if (!(td.year == now.year && td.month == now.month)) return false;
            break;
          case 'Next Month':
            if (!(td.year == now.year && td.month == now.month + 1)) return false;
            break;
          case 'This Year':
            if (td.year != now.year) return false;
            break;
          case 'Next Year':
            if (td.year != now.year + 1) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  Future<void> addGoal(String name, String description, DateTime? targetDate, String? context, bool isCompleted) async {
    final id = const Uuid().v4();
    final goal = Goal(
      id: id,
      name: name,
      description: description,
      targetDate: targetDate,
      context: context,
      isCompleted: isCompleted,
    );
    await create(goal);
    await loadGoals();
  }

  Future<void> editGoal(String id, String name, String description, DateTime? targetDate, String? context, bool isCompleted) async {
    final goal = Goal(
      id: id,
      name: name,
      description: description,
      targetDate: targetDate,
      context: context,
      isCompleted: isCompleted,
    );
    await update(goal);
    await loadGoals();
  }

  Future<void> removeGoal(String id) async {
    await delete(id);
    await loadGoals();
  }
}