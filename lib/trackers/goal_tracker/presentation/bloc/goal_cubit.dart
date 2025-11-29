import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/usecases/goal/get_all_goals.dart';
import '../../domain/usecases/goal/create_goal.dart';
import '../../domain/usecases/goal/update_goal.dart';
import '../../domain/usecases/goal/delete_goal.dart';
import '../../domain/usecases/milestone/get_all_milestones.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
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
  final GetAllMilestones getAllMilestones;
  final ViewPreferencesService viewPreferencesService;
  final FilterPreferencesService filterPreferencesService;
  final SortPreferencesService sortPreferencesService;

  // master copy of all goals fetched from the domain layer.
  List<Goal> _allGoals = []; // master copy of all goals
  String? _currentContextFilter;
  String? _currentTargetDateFilter;
  String? _currentGrouping; // e.g. 'context' or null
  
  // Sort-related state
  String _sortOrder = 'asc';
  bool _hideCompleted = true; // Default to true (hide completed items by default)

  static const Map<String, bool> _defaultVisibleFieldConfig = {
    'name': true,
    'description': true,
    'targetDate': false,
    'context': false,
    'remainingDays': false,
    'milestoneSummary': true,
  };

  // Visible fields configuration for presentation layer
  Map<String, bool> _visibleFields = Map<String, bool>.from(_defaultVisibleFieldConfig);
  Map<String, GoalMilestoneStats> _milestoneSummaries = const {};

  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);
  Map<String, GoalMilestoneStats> get milestoneSummaries =>
      Map<String, GoalMilestoneStats>.unmodifiable(_milestoneSummaries);

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(_defaultVisibleFieldConfig);
    _visibleFields.addAll(fields);
    _visibleFields['name'] = true;
    // Re-emit current view to trigger UI rebuild with new visibility
    if (state is GoalsLoaded) {
      final current = state as GoalsLoaded;
      emit(GoalsLoaded(List<Goal>.from(current.goals), visibleFields, milestoneSummaries));
    } else {
      emit(GoalsLoaded(List<Goal>.from(_allGoals), visibleFields, milestoneSummaries));
    }
  }

  String? get currentContextFilter => _currentContextFilter;
  String? get currentTargetDateFilter => _currentTargetDateFilter;
  String? get currentGrouping => _currentGrouping;
  String get currentSortOrder => _sortOrder;
  bool get hideCompleted => _hideCompleted;

  /// Returns true when any filter, grouping, or sort is active.
  bool get hasActiveFilters =>
      (_currentContextFilter != null && _currentContextFilter!.isNotEmpty) ||
      (_currentTargetDateFilter != null && _currentTargetDateFilter!.isNotEmpty) ||
      (_currentGrouping != null && _currentGrouping!.isNotEmpty) ||
      _sortOrder != 'asc';

  /// Human-readable summary of active filters for UI consumption.
  ///
  /// Examples:
  ///  - "Context: Work • Date: This Month • Sort: Descending"
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
    if (_sortOrder != 'asc') {
      parts.add('Sort: ${_sortOrder == 'desc' ? 'Descending' : 'Ascending'}');
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
    required this.getAllMilestones,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
    required this.sortPreferencesService,
  }) : super(GoalsLoading()) {
    _visibleFields = Map<String, bool>.from(_defaultVisibleFieldConfig);
    // Load saved view preferences on initialization
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.goal);
    if (savedPrefs != null) {
      _visibleFields.addAll(savedPrefs);
    }
    
    // Load saved filter preferences on initialization
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.goal);
    if (savedFilters != null) {
      _currentContextFilter = savedFilters['context'];
      _currentTargetDateFilter = savedFilters['targetDate'];
    }
    
    // Load saved sort preferences on initialization
    final savedSort = sortPreferencesService.loadSortPreferences(SortEntityType.goal);
    if (savedSort != null) {
      _sortOrder = savedSort['sortOrder'] ?? 'asc';
      _hideCompleted = savedSort['hideCompleted'] ?? true;
    }
  }

  Future<void> loadGoals() async {
    try {
      emit(GoalsLoading());
      final goals = await getAll();
      final milestones = await getAllMilestones();
      _allGoals = goals;
      _milestoneSummaries = _buildMilestoneSummaries(goals, milestones);
      
      // Apply any saved filters and sorting after loading data
      final filteredGoals = _filterGoals(_allGoals);
      final sortedGoals = _sortGoals(filteredGoals);
      emit(GoalsLoaded(sortedGoals, visibleFields, milestoneSummaries));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  void applyFilter({String? contextFilter, String? targetDateFilter, bool? hideCompleted}) {
    _currentContextFilter = contextFilter;
    _currentTargetDateFilter = targetDateFilter;
    if (hideCompleted != null) {
      _hideCompleted = hideCompleted;
    }

    final filtered = _filterGoals(_allGoals);
    final sorted = _sortGoals(filtered);
    emit(GoalsLoaded(sorted, visibleFields, milestoneSummaries));
  }

  void applySorting({required String sortOrder, required bool hideCompleted}) {
    _sortOrder = sortOrder;
    _hideCompleted = hideCompleted;

    final filtered = _filterGoals(_allGoals);
    final sorted = _sortGoals(filtered);
    emit(GoalsLoaded(sorted, visibleFields, milestoneSummaries));
  }

  void applyGrouping({required String groupBy}) {
    _currentGrouping = groupBy;
    debugPrint("🔎 Applying grouping by $groupBy");

    var filtered = _filterGoals(_allGoals);

    if (groupBy == 'context') {
      filtered.sort((a, b) {
        final aCtx = a.context ?? '';
        final bCtx = b.context ?? '';
        return aCtx.compareTo(bCtx);
      });
    }

    final sorted = _sortGoals(filtered);
    debugPrint("📊 Grouped goals count: ${sorted.length}");
    emit(GoalsLoaded(sorted, visibleFields, milestoneSummaries));
  }

  void clearFilters() {
    _currentContextFilter = null;
    _currentTargetDateFilter = null;
    _currentGrouping = null;
    _sortOrder = 'asc';
    _hideCompleted = true; // Reset to default (hide completed)
    emit(GoalsLoaded(List.from(_allGoals), visibleFields, milestoneSummaries));
  }

  List<Goal> _filterGoals(List<Goal> source) {
    final now = DateTime.now();

    return source.where((g) {
      // Hide completed filter
      if (_hideCompleted && g.isCompleted) {
        return false;
      }

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

  List<Goal> _sortGoals(List<Goal> goals) {
    final sorted = List<Goal>.from(goals);
    
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

  Map<String, GoalMilestoneStats> _buildMilestoneSummaries(List<Goal> goals, List<Milestone> milestones) {
    final byGoal = <String, List<Milestone>>{};
    for (final milestone in milestones) {
      byGoal.putIfAbsent(milestone.goalId, () => <Milestone>[]).add(milestone);
    }

    final result = <String, GoalMilestoneStats>{};

    for (final goal in goals) {
      final goalMilestones = byGoal[goal.id] ?? const <Milestone>[];
      final total = goalMilestones.length;
      if (total == 0) {
        result[goal.id] = const GoalMilestoneStats(
          openCount: 0,
          totalCount: 0,
          completionPercent: 0,
        );
        continue;
      }

      final completed = goalMilestones.where(_isMilestoneCompleted).length;
      final open = total - completed;
      final completionPercent = total == 0 ? 0.0 : (completed / total) * 100;

      result[goal.id] = GoalMilestoneStats(
        openCount: open,
        totalCount: total,
        completionPercent: completionPercent,
      );
    }

    return result;
  }

  bool _isMilestoneCompleted(Milestone milestone) {
    if (milestone.actualValue != null && milestone.plannedValue != null) {
      return milestone.actualValue! >= milestone.plannedValue!;
    }
    return false;
  }
}