/*
 * File: task_cubit.dart
 *
 * Purpose:
 * - Manages presentation state for Task entities within the Task feature.
 * - Loads, filters, creates, updates and deletes tasks by delegating to domain
 *   use-cases (GetAllTasks, GetTasksByMilestoneId, CreateTask, UpdateTask, DeleteTask).
 * - Holds an internal master copy (`_allTasks`) and emits filtered/derived
 *   views to the UI via TaskState.
 * - **CRITICAL BEHAVIOR**: Enforces auto-assignment of `goalId` from the associated
 *   Milestone during create/update operations. The UI must not directly set goalId.
 *
 * State & behavior notes:
 * - This cubit keeps a simple in-memory master list (`_allTasks`) and applies
 *   lightweight filtering/grouping in the presentation layer. For large datasets
 *   or complex queries consider pushing filters into the repository layer for efficiency.
 * - Filter keys are simple strings (e.g., 'This Month', 'This Year') — keep them stable.
 *
 * Developer guidance:
 * - Keep domain validation and persistence in the use-cases/repository; this
 *   cubit should orchestrate and transform results for UI consumption only.
 * - Avoid heavy synchronous computation here; prefer async streams or repo-side queries.
 * - The goalId auto-assignment logic is a critical business rule enforced here:
 *   when creating or updating a task, the cubit fetches the associated Milestone
 *   and sets the task's goalId from the milestone's goalId before persisting.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/milestone_repository.dart';
import '../../domain/usecases/task/create_task.dart';
import '../../domain/usecases/task/get_all_tasks.dart';
import '../../domain/usecases/task/get_task_by_id.dart';
import '../../domain/usecases/task/get_tasks_by_milestone_id.dart';
import '../../domain/usecases/task/update_task.dart';
import '../../domain/usecases/task/delete_task.dart';
import '../../core/view_preferences_service.dart';
import '../../core/filter_preferences_service.dart';
import '../../core/sort_preferences_service.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/goal_model.dart';
import '../../core/constants.dart';
import '../widgets/view_field_bottom_sheet.dart';
import '../widgets/filter_group_bottom_sheet.dart';
import 'task_state.dart';

/// Custom exception thrown when a milestone is not found during task create/update.
class MilestoneNotFoundException implements Exception {
  final String milestoneId;
  MilestoneNotFoundException(this.milestoneId);

  @override
  String toString() =>
      'MilestoneNotFoundException: Milestone with ID "$milestoneId" not found.';
}

/// Custom exception thrown when a milestone's goalId is null during task create/update.
class InvalidMilestoneException implements Exception {
  final String milestoneId;
  InvalidMilestoneException(this.milestoneId);

  @override
  String toString() =>
      'InvalidMilestoneException: Milestone "$milestoneId" has no associated goalId.';
}

/// Cubit to manage Task state.
class TaskCubit extends Cubit<TaskState> {
  final GetAllTasks getAll;
  final GetTaskById getById;
  final GetTasksByMilestoneId getByMilestoneId;
  final CreateTask create;
  final UpdateTask update;
  final DeleteTask delete;

  /// MilestoneRepository is required to fetch milestone details for goalId resolution.
  final MilestoneRepository milestoneRepository;
  
  /// ViewPreferencesService for loading/saving field visibility preferences.
  final ViewPreferencesService viewPreferencesService;
  
  /// FilterPreferencesService for loading/saving filter preferences.
  final FilterPreferencesService filterPreferencesService;
  
  /// SortPreferencesService for loading/saving sort preferences.
  final SortPreferencesService sortPreferencesService;

  // master copy of all tasks fetched from the domain layer.
  List<Task> _allTasks = [];

  // Optional filters / context
  String? _currentMilestoneIdFilter;
  String? _currentGoalIdFilter;
  String? _currentStatusFilter;
  String? _currentTargetDateFilter;
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideCompleted = false;

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = const {
    'name': true,
    'targetDate': true,
    'status': true,
    'milestoneId': false,
    'goalId': false,
  };

  Map<String, bool> get visibleFields =>
      Map<String, bool>.unmodifiable(_visibleFields);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    // Re-emit current view to trigger UI rebuild with new visibility
    if (state is TasksLoaded) {
      final current = state as TasksLoaded;
      emit(TasksLoaded(List<Task>.from(current.tasks),
          milestoneId: current.milestoneId,
          goalId: current.goalId,
          visibleFields: visibleFields));
    } else {
      emit(TasksLoaded(List<Task>.from(_allTasks), visibleFields: visibleFields));
    }
  }

  String? get currentMilestoneIdFilter => _currentMilestoneIdFilter;
  String? get currentGoalIdFilter => _currentGoalIdFilter;
  String? get currentStatusFilter => _currentStatusFilter;
  String? get currentTargetDateFilter => _currentTargetDateFilter;
  String get currentSortOrder => _sortOrder;
  bool get hideCompleted => _hideCompleted;

  /// Returns true when any filter or sort is active.
  bool get hasActiveFilters =>
      (_currentMilestoneIdFilter != null &&
          _currentMilestoneIdFilter!.isNotEmpty) ||
      (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) ||
      (_currentStatusFilter != null && _currentStatusFilter!.isNotEmpty) ||
      (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) ||
      _sortOrder != 'asc' ||
      _hideCompleted;

  /// Human-readable summary of active filters for UI consumption.
  String get filterSummary {
    final parts = <String>[];

    if (_currentMilestoneIdFilter != null &&
        _currentMilestoneIdFilter!.isNotEmpty) {
      try {
        final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
        final milestone = milestoneBox.get(_currentMilestoneIdFilter);
        final milestoneName = milestone?.name ?? _currentMilestoneIdFilter!;
        parts.add('Milestone: $milestoneName');
      } catch (e) {
        parts.add('Milestone: ${_currentMilestoneIdFilter!}');
      }
    }
    if (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) {
      try {
        final goalBox = Hive.box<GoalModel>(goalBoxName);
        final goal = goalBox.get(_currentGoalIdFilter);
        final goalName = goal?.name ?? _currentGoalIdFilter!;
        parts.add('Goal: $goalName');
      } catch (e) {
        parts.add('Goal: ${_currentGoalIdFilter!}');
      }
    }
    if (_currentStatusFilter != null && _currentStatusFilter!.isNotEmpty) {
      parts.add('Status: ${_currentStatusFilter!}');
    }
    if (_currentTargetDateFilter != null &&
        _currentTargetDateFilter!.isNotEmpty) {
      parts.add('Date: ${_currentTargetDateFilter!}');
    }
    if (_sortOrder != 'asc') {
      parts.add('Sort: ${_sortOrder == 'desc' ? 'Descending' : 'Ascending'}');
    }
    if (_hideCompleted) {
      parts.add('Hide Completed');
    }

    if (parts.isEmpty) {
      return 'Filters applied';
    }

    return parts.join(' • ');
  }

  TaskCubit({
    required this.getAll,
    required this.getById,
    required this.getByMilestoneId,
    required this.create,
    required this.update,
    required this.delete,
    required this.milestoneRepository,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
    required this.sortPreferencesService,
  }) : super(TasksLoading()) {
    // Load saved view preferences on initialization
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.task);
    if (savedPrefs != null) {
      _visibleFields = savedPrefs;
    }
    
    // Load saved filter preferences on initialization
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.task);
    if (savedFilters != null) {
      _currentMilestoneIdFilter = savedFilters['milestoneId'];
      _currentGoalIdFilter = savedFilters['goalId'];
      _currentStatusFilter = savedFilters['status'];
      _currentTargetDateFilter = savedFilters['targetDate'];
    }
    
    // Load saved sort preferences on initialization
    final savedSort = sortPreferencesService.loadSortPreferences(SortEntityType.task);
    if (savedSort != null) {
      _sortOrder = savedSort['sortOrder'] ?? 'asc';
      _hideCompleted = savedSort['hideCompleted'] ?? false;
    }
  }

  /// Load all tasks from repository.
  Future<void> loadTasks() async {
    try {
      emit(TasksLoading());
      final data = await getAll();
      _allTasks = data;
      
      // Apply any saved filters and sorting after loading data
      final filteredTasks = _filterTasks(_allTasks);
      final sortedTasks = _sortTasks(filteredTasks);
      emit(TasksLoaded(sortedTasks, visibleFields: visibleFields));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Load tasks for a specific milestone.
  Future<void> loadTasksByMilestoneId(String milestoneId) async {
    try {
      emit(TasksLoading());
      final data = await getByMilestoneId(milestoneId);
      _currentMilestoneIdFilter = milestoneId;
      emit(TasksLoaded(List.from(data),
          milestoneId: milestoneId, visibleFields: visibleFields));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Load a single task by id and emit a loaded state containing that single item.
  Future<void> loadTaskById(String id) async {
    try {
      emit(TasksLoading());
      final t = await getById(id);
      final list = t != null ? [t] : <Task>[];
      emit(TasksLoaded(list, visibleFields: visibleFields));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Apply filters (milestoneId, goalId, status, and/or targetDate).
  void applyFilter({
    String? milestoneId,
    String? goalId,
    String? status,
    String? targetDateFilter,
  }) {
    _currentMilestoneIdFilter = milestoneId;
    _currentGoalIdFilter = goalId;
    _currentStatusFilter = status;
    _currentTargetDateFilter = targetDateFilter;

    final filtered = _filterTasks(_allTasks);
    final sorted = _sortTasks(filtered);
    emit(TasksLoaded(sorted,
        milestoneId: _currentMilestoneIdFilter,
        goalId: _currentGoalIdFilter,
        visibleFields: visibleFields));
  }

  void applySorting({required String sortOrder, required bool hideCompleted}) {
    _sortOrder = sortOrder;
    _hideCompleted = hideCompleted;

    final filtered = _filterTasks(_allTasks);
    final sorted = _sortTasks(filtered);
    emit(TasksLoaded(sorted,
        milestoneId: _currentMilestoneIdFilter,
        goalId: _currentGoalIdFilter,
        visibleFields: visibleFields));
  }

  /// Clear applied filters and emit the full list.
  void clearFilters() {
    _currentMilestoneIdFilter = null;
    _currentGoalIdFilter = null;
    _currentStatusFilter = null;
    _currentTargetDateFilter = null;
    _sortOrder = 'asc';
    _hideCompleted = false;
    emit(TasksLoaded(List.from(_allTasks), visibleFields: visibleFields));
  }

  List<Task> _filterTasks(List<Task> source) {
    final now = DateTime.now();

    return source.where((t) {
      // Hide completed filter
      if (_hideCompleted && t.status == 'Complete') {
        return false;
      }

      // Milestone filter
      if (_currentMilestoneIdFilter != null &&
          _currentMilestoneIdFilter!.isNotEmpty) {
        if (t.milestoneId != _currentMilestoneIdFilter) return false;
      }

      // Goal filter
      if (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) {
        if (t.goalId != _currentGoalIdFilter) return false;
      }

      // Status filter
      if (_currentStatusFilter != null && _currentStatusFilter!.isNotEmpty) {
        if (t.status != _currentStatusFilter) return false;
      }

      // Target date filter
      if (_currentTargetDateFilter != null) {
        final tf = _currentTargetDateFilter!;
        final td = t.targetDate;
        if (td == null) return false;

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
            final nextMonth = DateTime(now.year, now.month + 1);
            if (!(td.year == nextMonth.year && td.month == nextMonth.month)) return false;
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

  List<Task> _sortTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    
    sorted.sort((a, b) {
      // Handle null target dates - always place at end
      if (a.targetDate == null && b.targetDate == null) return 0;
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      
      // Compare target dates
      final comparison = a.targetDate!.compareTo(b.targetDate!);
      
      // Apply sort order
      return _sortOrder == 'desc' ? -comparison : comparison;
    });
    
    return sorted;
  }

  /// Create a new task and reload list.
  ///
  /// **CRITICAL LOGIC**: This method fetches the associated Milestone to retrieve
  /// its goalId and auto-sets it on the task before persisting. The UI must not
  /// provide goalId directly; it will be ignored.
  ///
  /// Throws:
  /// - [MilestoneNotFoundException] if the milestone does not exist.
  /// - [InvalidMilestoneException] if the milestone's goalId is null.
  Future<void> addTask({
    required String name,
    DateTime? targetDate,
    required String milestoneId,
    String status = 'To Do',
  }) async {
    try {
      // Fetch the milestone to get its goalId
      final milestone = await milestoneRepository.getMilestoneById(milestoneId);

      if (milestone == null) {
        throw MilestoneNotFoundException(milestoneId);
      }

      // Validate that the milestone has a goalId
      if (milestone.goalId.isEmpty) {
        throw InvalidMilestoneException(milestoneId);
      }

      // Auto-assign goalId from milestone
      final id = const Uuid().v4();
      final task = Task(
        id: id,
        name: name,
        targetDate: targetDate,
        milestoneId: milestoneId,
        goalId: milestone.goalId, // AUTO-ASSIGNED from milestone
        status: status,
      );

      await create(task);
      // Refresh master list from repository to reflect persisted state.
      await loadTasks();
    } on MilestoneNotFoundException {
      rethrow;
    } on InvalidMilestoneException {
      rethrow;
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Edit an existing task and reload list.
  ///
  /// **CRITICAL LOGIC**: This method fetches the associated Milestone to retrieve
  /// its goalId and auto-sets it on the task before persisting. The UI must not
  /// provide goalId directly; it will be ignored.
  ///
  /// Throws:
  /// - [MilestoneNotFoundException] if the milestone does not exist.
  /// - [InvalidMilestoneException] if the milestone's goalId is null.
  Future<void> editTask({
    required String id,
    required String name,
    DateTime? targetDate,
    required String milestoneId,
    required String status,
  }) async {
    try {
      // Fetch the milestone to get its goalId
      final milestone = await milestoneRepository.getMilestoneById(milestoneId);

      if (milestone == null) {
        throw MilestoneNotFoundException(milestoneId);
      }

      // Validate that the milestone has a goalId
      if (milestone.goalId.isEmpty) {
        throw InvalidMilestoneException(milestoneId);
      }

      // Auto-assign goalId from milestone
      final task = Task(
        id: id,
        name: name,
        targetDate: targetDate,
        milestoneId: milestoneId,
        goalId: milestone.goalId, // AUTO-ASSIGNED from milestone
        status: status,
      );

      await update(task);
      await loadTasks();
    } on MilestoneNotFoundException {
      rethrow;
    } on InvalidMilestoneException {
      rethrow;
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Remove a task and reload list.
  Future<void> removeTask(String id) async {
    try {
      await delete(id);
      await loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}

