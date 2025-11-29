/*
 * File: milestone_cubit.dart
 *
 * Purpose:
 * - Manages presentation state for Milestone entities within the Milestone feature.
 * - Loads, filters, creates, updates and deletes milestones by delegating to domain
 *   use-cases (GetAllMilestones, GetMilestonesByGoalId, CreateMilestone, UpdateMilestone, DeleteMilestone).
 * - Holds an internal master copy (`_allMilestones`) and emits filtered/derived
 *   views to the UI via MilestoneState.
 *
 * State & behavior notes:
 * - This cubit keeps a simple in-memory master list (`_allMilestones`) and applies
 *   lightweight filtering/grouping in the presentation layer. For large datasets
 *   or complex queries consider pushing filters into the repository layer for efficiency.
 * - Filter keys are simple strings (e.g., 'This Month', 'This Year') — keep them stable.
 *
 * Developer guidance:
 * - Keep domain validation and persistence in the use-cases/repository; this
 *   cubit should orchestrate and transform results for UI consumption only.
 * - Avoid heavy synchronous computation here; prefer async streams or repo-side queries.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/milestone.dart';
import '../../domain/usecases/milestone/create_milestone.dart';
import '../../domain/usecases/milestone/get_all_milestones.dart';
import '../../domain/usecases/milestone/get_milestone_by_id.dart';
import '../../domain/usecases/milestone/get_milestones_by_goal_id.dart';
import '../../domain/usecases/milestone/update_milestone.dart';
import '../../domain/usecases/milestone/delete_milestone.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
import '../../data/models/goal_model.dart';
import '../../core/constants.dart';
import 'milestone_state.dart';

/// Cubit to manage Milestone state.
class MilestoneCubit extends Cubit<MilestoneState> {
  final GetAllMilestones getAll;
  final GetMilestoneById getById;
  final GetMilestonesByGoalId getByGoalId;
  final CreateMilestone create;
  final UpdateMilestone update;
  final DeleteMilestone delete;
  
  /// ViewPreferencesService for loading/saving field visibility preferences.
  final ViewPreferencesService viewPreferencesService;
  
  /// FilterPreferencesService for loading/saving filter preferences.
  final FilterPreferencesService filterPreferencesService;
  
  /// SortPreferencesService for loading/saving sort preferences.
  final SortPreferencesService sortPreferencesService;

  // master copy of all milestones fetched from the domain layer.
  List<Milestone> _allMilestones = [];

  // Optional filters / context
  String? _currentGoalIdFilter;
  String? _currentTargetDateFilter;
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideCompleted = true; // Default to true (hide completed items by default)

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = const {
    'name': true,
    'description': true,
    'plannedValue': true,
    'actualValue': true,
    'targetDate': false,
    'goalId': false,
  };

  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    // Re-emit current view to trigger UI rebuild with new visibility
    if (state is MilestonesLoaded) {
      final current = state as MilestonesLoaded;
      emit(MilestonesLoaded(List<Milestone>.from(current.milestones),
          goalId: current.goalId, visibleFields: visibleFields));
    } else {
      emit(MilestonesLoaded(List<Milestone>.from(_allMilestones), visibleFields: visibleFields));
    }
  }

  String? get currentGoalIdFilter => _currentGoalIdFilter;
  String? get currentTargetDateFilter => _currentTargetDateFilter;
  String get currentSortOrder => _sortOrder;
  bool get hideCompleted => _hideCompleted;

  /// Returns true when any filter or sort is active.
  bool get hasActiveFilters =>
      (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) ||
      (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) ||
      _sortOrder != 'asc';

  /// Human-readable summary of active filters for UI consumption.
  String get filterSummary {
    final parts = <String>[];

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
    if (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) {
      parts.add('Date: ${_currentTargetDateFilter!}');
    }
    if (_sortOrder != 'asc') {
      parts.add('Sort: ${_sortOrder == 'desc' ? 'Descending' : 'Ascending'}');
    }

    if (parts.isEmpty) {
      return 'Filters applied';
    }

    return parts.join(' • ');
  }

  MilestoneCubit({
    required this.getAll,
    required this.getById,
    required this.getByGoalId,
    required this.create,
    required this.update,
    required this.delete,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
    required this.sortPreferencesService,
  }) : super(MilestonesLoading()) {
    // Load saved view preferences on initialization
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.milestone);
    if (savedPrefs != null) {
      _visibleFields = savedPrefs;
    }
    
    // Load saved filter preferences on initialization
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.milestone);
    if (savedFilters != null) {
      _currentGoalIdFilter = savedFilters['context']; // context is used for goalId in milestone filters
      _currentTargetDateFilter = savedFilters['targetDate'];
    }
    
    // Load saved sort preferences on initialization
    final savedSort = sortPreferencesService.loadSortPreferences(SortEntityType.milestone);
    if (savedSort != null) {
      _sortOrder = savedSort['sortOrder'] ?? 'asc';
      _hideCompleted = savedSort['hideCompleted'] ?? true;
    }
  }

  /// Load all milestones from repository.
  Future<void> loadMilestones() async {
    try {
      emit(MilestonesLoading());
      final data = await getAll();
      _allMilestones = data;
      
      // Apply any saved filters and sorting after loading data
      final filteredMilestones = _filterMilestones(_allMilestones);
      final sortedMilestones = _sortMilestones(filteredMilestones);
      emit(MilestonesLoaded(sortedMilestones, visibleFields: visibleFields));
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }

  /// Load milestones for a specific goal.
  Future<void> loadMilestonesByGoalId(String goalId) async {
    try {
      emit(MilestonesLoading());
      final data = await getByGoalId(goalId);
      // Keep master copy but also set current goal filter for presentation.
      // We keep all fetched into master if user expects global view; here we keep both.
      _currentGoalIdFilter = goalId;
      emit(MilestonesLoaded(List.from(data), goalId: goalId, visibleFields: visibleFields));
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }

  /// Load a single milestone by id and emit a loaded state containing that single item.
  Future<void> loadMilestoneById(String id) async {
    try {
      emit(MilestonesLoading());
      final m = await getById(id);
      final list = m != null ? [m] : <Milestone>[];
      emit(MilestonesLoaded(list, visibleFields: visibleFields));
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }

  /// Apply filters (goalId and/or targetDate).
  void applyFilter({String? goalId, String? targetDateFilter, bool? hideCompleted}) {
    _currentGoalIdFilter = goalId;
    _currentTargetDateFilter = targetDateFilter;
    if (hideCompleted != null) {
      _hideCompleted = hideCompleted;
    }

    final filtered = _filterMilestones(_allMilestones);
    final sorted = _sortMilestones(filtered);
    emit(MilestonesLoaded(sorted, goalId: _currentGoalIdFilter, visibleFields: visibleFields));
  }

  void applySorting({required String sortOrder, required bool hideCompleted}) {
    _sortOrder = sortOrder;
    _hideCompleted = hideCompleted;

    final filtered = _filterMilestones(_allMilestones);
    final sorted = _sortMilestones(filtered);
    emit(MilestonesLoaded(sorted, goalId: _currentGoalIdFilter, visibleFields: visibleFields));
  }

  /// Clear applied filters and emit the full list.
  void clearFilters() {
    _currentGoalIdFilter = null;
    _currentTargetDateFilter = null;
    _sortOrder = 'asc';
    _hideCompleted = true; // Reset to default (hide completed)
    emit(MilestonesLoaded(List.from(_allMilestones), visibleFields: visibleFields));
  }

  List<Milestone> _filterMilestones(List<Milestone> source) {
    final now = DateTime.now();

    return source.where((m) {
      // Hide completed filter - milestone is considered completed if actualValue is not null and equals or exceeds plannedValue
      if (_hideCompleted) {
        if (m.actualValue != null && m.plannedValue != null) {
          if (m.actualValue! >= m.plannedValue!) {
            return false; // Hide completed milestones
          }
        }
      }

      // Goal filter
      if (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) {
        if (m.goalId != _currentGoalIdFilter) return false;
      }

      // Target date filter
      if (_currentTargetDateFilter != null) {
        final tf = _currentTargetDateFilter!;
        final td = m.targetDate;
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

  List<Milestone> _sortMilestones(List<Milestone> milestones) {
    final sorted = List<Milestone>.from(milestones);
    
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

  /// Create a new milestone and reload list.
  Future<void> addMilestone({
    required String name,
    String? description,
    double? plannedValue,
    double? actualValue,
    DateTime? targetDate,
    required String goalId,
  }) async {
    final id = const Uuid().v4();
    final milestone = Milestone(
      id: id,
      name: name,
      description: description,
      plannedValue: plannedValue,
      actualValue: actualValue,
      targetDate: targetDate,
      goalId: goalId,
    );

    try {
      await create(milestone);
      // Refresh master list from repository to reflect persisted state.
      await loadMilestones();
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }

  /// Edit an existing milestone and reload list.
  Future<void> editMilestone({
    required String id,
    required String name,
    String? description,
    double? plannedValue,
    double? actualValue,
    DateTime? targetDate,
    required String goalId,
  }) async {
    final milestone = Milestone(
      id: id,
      name: name,
      description: description,
      plannedValue: plannedValue,
      actualValue: actualValue,
      targetDate: targetDate,
      goalId: goalId,
    );

    try {
      await update(milestone);
      await loadMilestones();
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }

  /// Remove a milestone and reload list.
  Future<void> removeMilestone(String id) async {
    try {
      await delete(id);
      await loadMilestones();
    } catch (e) {
      emit(MilestonesError(e.toString()));
    }
  }
}
