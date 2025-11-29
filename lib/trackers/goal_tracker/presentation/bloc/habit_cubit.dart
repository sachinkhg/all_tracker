/*
 * File: habit_cubit.dart
 *
 * Purpose:
 * - Manages presentation state for Habit entities within the Habit feature.
 * - Loads, filters, creates, updates and deletes habits by delegating to domain
 *   use-cases (GetAllHabits, GetHabitsByMilestoneId, CreateHabit, UpdateHabit, DeleteHabit).
 * - Holds an internal master copy (`_allHabits`) and emits filtered/derived
 *   views to the UI via HabitState.
 * - Auto-assigns goalId from milestone when creating/editing habits.
 *
 * State & behavior notes:
 * - This cubit keeps a simple in-memory master list (`_allHabits`) and applies
 *   lightweight filtering/grouping in the presentation layer.
 * - Filter keys are simple strings (e.g., 'Active', 'Inactive') — keep them stable.
 * - Business rule: goalId is auto-assigned from milestone relationship.
 *
 * Developer guidance:
 * - Keep domain validation and persistence in the use-cases/repository; this
 *   cubit should orchestrate and transform results for UI consumption only.
 * - Avoid heavy synchronous computation here; prefer async streams or repo-side queries.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/habit.dart';
import '../../domain/usecases/habit/create_habit.dart';
import '../../domain/usecases/habit/get_all_habits.dart';
import '../../domain/usecases/habit/get_habit_by_id.dart';
import '../../domain/usecases/habit/get_habits_by_milestone_id.dart';
import '../../domain/usecases/habit/update_habit.dart';
import '../../domain/usecases/habit/delete_habit.dart';
import '../../domain/repositories/milestone_repository.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/goal_model.dart';
import '../../core/constants.dart';
import 'habit_state.dart';

/// Cubit to manage Habit state.
class HabitCubit extends Cubit<HabitState> {
  final GetAllHabits getAll;
  final GetHabitById getById;
  final GetHabitsByMilestoneId getByMilestoneId;
  final CreateHabit create;
  final UpdateHabit update;
  final DeleteHabit delete;
  final MilestoneRepository milestoneRepository;
  
  /// ViewPreferencesService for loading/saving field visibility preferences.
  final ViewPreferencesService viewPreferencesService;
  
  /// FilterPreferencesService for loading/saving filter preferences.
  final FilterPreferencesService filterPreferencesService;
  
  /// SortPreferencesService for loading/saving sort preferences.
  final SortPreferencesService sortPreferencesService;

  // master copy of all habits fetched from the domain layer.
  List<Habit> _allHabits = [];

  // Optional filters / context
  String? _currentMilestoneIdFilter;
  String? _currentGoalIdFilter;
  String? _currentStatusFilter; // 'Active', 'Inactive', 'All'
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideInactive = true; // Default to true (hide inactive items by default)

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = const {
    'name': true,
    'description': true,
    'milestoneName': false,
    'goalName': false,
    'rrule': false,
    'targetCompletions': false,
    'isActive': false,
  };

  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    // Re-emit current view to trigger UI rebuild with new visibility
    if (state is HabitsLoaded) {
      final current = state as HabitsLoaded;
      emit(HabitsLoaded(List<Habit>.from(current.habits),
          milestoneId: current.milestoneId, visibleFields: visibleFields));
    } else {
      emit(HabitsLoaded(List<Habit>.from(_allHabits), visibleFields: visibleFields));
    }
  }

  String? get currentMilestoneIdFilter => _currentMilestoneIdFilter;
  String? get currentGoalIdFilter => _currentGoalIdFilter;
  String? get currentStatusFilter => _currentStatusFilter;
  String get currentSortOrder => _sortOrder;
  bool get hideInactive => _hideInactive;

  /// Returns true when any filter or sort is active.
  bool get hasActiveFilters =>
      (_currentMilestoneIdFilter != null && _currentMilestoneIdFilter!.isNotEmpty) ||
      (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) ||
      (_currentStatusFilter != null && _currentStatusFilter != 'All') ||
      _sortOrder != 'asc';

  /// Human-readable summary of active filters for UI consumption.
  String get filterSummary {
    final parts = <String>[];

    if (_currentMilestoneIdFilter != null && _currentMilestoneIdFilter!.isNotEmpty) {
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
    if (_currentStatusFilter != null && _currentStatusFilter != 'All') {
      parts.add('Status: ${_currentStatusFilter!}');
    }
    if (_sortOrder != 'asc') {
      parts.add('Sort: ${_sortOrder == 'desc' ? 'Descending' : 'Ascending'}');
    }

    if (parts.isEmpty) {
      return 'Filters applied';
    }

    return parts.join(' • ');
  }

  HabitCubit({
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
  }) : super(const HabitsLoading()) {
    // Load saved view preferences on initialization
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.habit);
    if (savedPrefs != null) {
      _visibleFields = savedPrefs;
    }
    
    // Load saved filter preferences on initialization
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.habit);
    if (savedFilters != null) {
      _currentMilestoneIdFilter = savedFilters['milestoneId'];
      _currentGoalIdFilter = savedFilters['goalId'];
      _currentStatusFilter = savedFilters['status'];
    }
    
    // Load saved sort preferences on initialization
    final savedSort = sortPreferencesService.loadSortPreferences(SortEntityType.habit);
    if (savedSort != null) {
      _sortOrder = savedSort['sortOrder'] ?? 'asc';
      // Support both 'hideCompleted' (from filter) and 'hideInactive' (from sort) keys
      _hideInactive = savedSort['hideCompleted'] ?? savedSort['hideInactive'] ?? true;
    }
  }

  /// Load all habits from repository.
  Future<void> loadHabits() async {
    try {
      emit(const HabitsLoading());
      final data = await getAll();
      _allHabits = data;
      
      // Apply any saved filters and sorting after loading data
      final filteredHabits = _filterHabits(_allHabits);
      final sortedHabits = _sortHabits(filteredHabits);
      emit(HabitsLoaded(sortedHabits, visibleFields: visibleFields));
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Load habits for a specific milestone.
  Future<void> loadHabitsByMilestoneId(String milestoneId) async {
    try {
      emit(const HabitsLoading());
      final data = await getByMilestoneId(milestoneId);
      // Keep master copy but also set current milestone filter for presentation.
      _currentMilestoneIdFilter = milestoneId;
      emit(HabitsLoaded(List.from(data), milestoneId: milestoneId, visibleFields: visibleFields));
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Load a single habit by id and emit a loaded state containing that single item.
  Future<void> loadHabitById(String id) async {
    try {
      emit(const HabitsLoading());
      final h = await getById(id);
      final list = h != null ? [h] : <Habit>[];
      emit(HabitsLoaded(list, visibleFields: visibleFields));
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Apply filters (milestoneId, goalId and/or status).
  void applyFilter({String? milestoneId, String? goalId, String? statusFilter, bool? hideCompleted}) {
    _currentMilestoneIdFilter = milestoneId;
    _currentGoalIdFilter = goalId;
    _currentStatusFilter = statusFilter;
    // Map hideCompleted to hideInactive for habits
    if (hideCompleted != null) {
      _hideInactive = hideCompleted;
    }

    final filtered = _filterHabits(_allHabits);
    final sorted = _sortHabits(filtered);
    emit(HabitsLoaded(sorted, milestoneId: _currentMilestoneIdFilter, visibleFields: visibleFields));
  }

  void applySorting({required String sortOrder, required bool hideInactive}) {
    _sortOrder = sortOrder;
    _hideInactive = hideInactive;

    final filtered = _filterHabits(_allHabits);
    final sorted = _sortHabits(filtered);
    emit(HabitsLoaded(sorted, milestoneId: _currentMilestoneIdFilter, visibleFields: visibleFields));
  }

  /// Clear applied filters and emit the full list.
  void clearFilters() {
    _currentMilestoneIdFilter = null;
    _currentGoalIdFilter = null;
    _currentStatusFilter = null;
    _sortOrder = 'asc';
    _hideInactive = true; // Reset to default (hide inactive)
    emit(HabitsLoaded(List.from(_allHabits), visibleFields: visibleFields));
  }

  List<Habit> _filterHabits(List<Habit> source) {
    return source.where((h) {
      // Hide inactive filter
      if (_hideInactive && !h.isActive) {
        return false;
      }

      // Milestone filter
      if (_currentMilestoneIdFilter != null && _currentMilestoneIdFilter!.isNotEmpty) {
        if (h.milestoneId != _currentMilestoneIdFilter) return false;
      }

      // Goal filter
      if (_currentGoalIdFilter != null && _currentGoalIdFilter!.isNotEmpty) {
        if (h.goalId != _currentGoalIdFilter) return false;
      }

      // Status filter
      if (_currentStatusFilter != null && _currentStatusFilter != 'All') {
        if (_currentStatusFilter == 'Active' && !h.isActive) return false;
        if (_currentStatusFilter == 'Inactive' && h.isActive) return false;
      }

      return true;
    }).toList();
  }

  List<Habit> _sortHabits(List<Habit> habits) {
    final sorted = List<Habit>.from(habits);
    
    sorted.sort((a, b) {
      // Sort by name
      final comparison = a.name.compareTo(b.name);
      
      // Apply sort order
      return _sortOrder == 'desc' ? -comparison : comparison;
    });
    
    return sorted;
  }

  /// Create a new habit and reload list.
  Future<void> addHabit({
    required String name,
    String? description,
    required String milestoneId,
    required String rrule,
    int? targetCompletions,
    bool isActive = true,
  }) async {
    try {
      // Auto-assign goalId from milestone
      final milestone = await milestoneRepository.getMilestoneById(milestoneId);
      if (milestone == null) {
        emit(HabitsError('Milestone not found'));
        return;
      }

      final id = const Uuid().v4();
      final habit = Habit(
        id: id,
        name: name,
        description: description,
        milestoneId: milestoneId,
        goalId: milestone.goalId, // Auto-assigned from milestone
        rrule: rrule,
        targetCompletions: targetCompletions,
        isActive: isActive,
      );

      await create(habit);
      // Refresh master list from repository to reflect persisted state.
      await loadHabits();
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Edit an existing habit and reload list.
  Future<void> editHabit({
    required String id,
    required String name,
    String? description,
    required String milestoneId,
    required String rrule,
    int? targetCompletions,
    bool isActive = true,
  }) async {
    try {
      // Auto-assign goalId from milestone
      final milestone = await milestoneRepository.getMilestoneById(milestoneId);
      if (milestone == null) {
        emit(HabitsError('Milestone not found'));
        return;
      }

      final habit = Habit(
        id: id,
        name: name,
        description: description,
        milestoneId: milestoneId,
        goalId: milestone.goalId, // Auto-assigned from milestone
        rrule: rrule,
        targetCompletions: targetCompletions,
        isActive: isActive,
      );

      await update(habit);
      await loadHabits();
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Remove a habit and reload list.
  Future<void> removeHabit(String id) async {
    try {
      await delete(id);
      await loadHabits();
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  /// Toggle habit active status.
  Future<void> toggleActive(String id) async {
    try {
      final habit = await getById(id);
      if (habit == null) {
        emit(HabitsError('Habit not found'));
        return;
      }

      final updatedHabit = Habit(
        id: habit.id,
        name: habit.name,
        description: habit.description,
        milestoneId: habit.milestoneId,
        goalId: habit.goalId,
        rrule: habit.rrule,
        targetCompletions: habit.targetCompletions,
        isActive: !habit.isActive,
      );

      await update(updatedHabit);
      await loadHabits();
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }
}
