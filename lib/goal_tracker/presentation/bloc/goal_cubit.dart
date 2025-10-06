import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/usecases/get_all_goals.dart';
import '../../domain/usecases/create_goal.dart';
import '../../domain/usecases/update_goal.dart';
import '../../domain/usecases/delete_goal.dart';
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
  // Mutations reload from source to keep master list consistent.
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
  ///
  /// This helper is useful for showing a "clear filters" affordance in the UI.
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

  /// Load all goals from the domain layer and emit a loaded state.
  ///
  /// Emits [GoalsLoading] before the fetch and [GoalsLoaded] with a copy of
  /// the received list on success; on failure emits [GoalsError] containing
  /// the error message.
  Future<void> loadGoals() async {
    try {
      emit(GoalsLoading());
      final data = await getAll();
      _allGoals = data;
      // Emit a defensive copy to avoid external mutation of internal list.
      emit(GoalsLoaded(List.from(_allGoals), visibleFields));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  /// Apply filters and emit a filtered view.
  ///
  /// The filters are stored in the cubit so subsequent operations (e.g.
  /// grouping) operate on the same filter set.
  void applyFilter({String? contextFilter, String? targetDateFilter}) {
    _currentContextFilter = contextFilter;
    _currentTargetDateFilter = targetDateFilter;

    final filtered = _filterGoals(_allGoals);
    emit(GoalsLoaded(filtered, visibleFields));
  }

  /// Apply grouping (presentation-only).
  ///
  /// Currently supports 'context' grouping which sorts goals by their context.
  /// Grouping is applied after filters. For complex grouping (buckets, headers)
  /// consider returning a grouped DTO rather than a flat list.
  void applyGrouping({required String groupBy}) {
    _currentGrouping = groupBy;
    print("🔎 Applying grouping by $groupBy");

    var filtered = _filterGoals(_allGoals);

    if (groupBy == 'context') {
      // Simple lexicographic sort by context; null contexts become empty strings.
      filtered.sort((a, b) {
        final aCtx = a.context ?? '';
        final bCtx = b.context ?? '';
        return aCtx.compareTo(bCtx);
      });
    }

    print("📊 Grouped goals count: ${filtered.length}");
    emit(GoalsLoaded(filtered, visibleFields));
  }

  /// Clear all active filters and grouping, restoring the master list view.
  void clearFilters() {
    _currentContextFilter = null;
    _currentTargetDateFilter = null;
    _currentGrouping = null;
    emit(GoalsLoaded(List.from(_allGoals), visibleFields));
  }

  /// Internal: filtering logic applied to a source list.
  ///
  /// Notes on date filtering:
  /// - The `targetDate` filters use simple comparisons against the current
  ///   system date (This Month, This Year, Next Month, Next Year).
  /// - Edge case: the 'Next Month' logic uses `now.month + 1`. This does not
  ///   normalize month>12 into the next year — keep that in mind if you
  ///   encounter incorrect matches around December/January; consider moving
  ///   date-range calculations to a helper that normalizes month/year.
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
          // If the goal has no target date, it cannot match any target-date filter.
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
            // NOTE: simple next-month check; does not currently handle year rollover.
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

  /// Create a new goal by delegating to the CreateGoal use-case.
  ///
  /// Generates a UUID for the new goal id, constructs a [Goal] entity and
  /// invokes the domain create use-case. Reloads the goals after creation to
  /// refresh the master list.
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

  /// Update an existing goal.
  ///
  /// Constructs a [Goal] with provided values and delegates to the update
  /// use-case. After update, reloads all goals to keep the master list in sync.
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

  /// Delete a goal and reload the master list.
  Future<void> removeGoal(String id) async {
    await delete(id);
    await loadGoals();
  }
}
