import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import 'package:all_tracker/core/hive/app_preferences_hive_initializer.dart';
import 'package:all_tracker/trackers/goal_tracker/core/hive_initializer.dart' as goal_tracker;
import 'package:all_tracker/trackers/travel_tracker/core/hive_initializer.dart' as travel_tracker;
import 'package:all_tracker/utilities/investment_planner/core/hive_initializer.dart' as investment_planner;
import 'package:all_tracker/utilities/retirement_planner/core/hive_initializer.dart' as retirement_planner;
import 'package:all_tracker/features/backup/core/hive_initializer.dart' as backup;
import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/trackers/goal_tracker/core/constants.dart';

/// Hive initializer for the app.
///
/// Responsibility:
/// - Discovers and calls all module-specific Hive initializers.
/// - Ensures all adapters are registered and boxes are opened before the app runs.
/// - Each module manages its own adapters and boxes via HiveModuleInitializer interface.
///
/// Boot order:
/// - MUST be called early in app startup (before DI finalization and before `runApp`).
///   Typical place: `main()` — perform `await HiveInitializer.initialize()` before constructing the DI graph
///   so repositories/data-sources find opened boxes.
///
/// Module-based architecture:
/// - Each module implements HiveModuleInitializer to register its own adapters and open its own boxes.
/// - Adding a new module: create a HiveModuleInitializer implementation and add it to the _moduleInitializers list.
/// - This approach ensures modules are self-contained and the central initializer remains simple.
///
/// Migration guidance:
/// - When adding a new Hive model:
///   1. Create the model and its generated adapter (or manual adapter).
///   2. Assign a unique `typeId` in the adapter. Record the new typeId and a short description in `migration_notes.md`.
///   3. Register the adapter in the module's HiveModuleInitializer implementation.
/// - If changing an existing model's fields:
///   * Prefer additive changes (new nullable fields). For breaking changes, add explicit migration code and document it in `migration_notes.md`.
///   * NEVER reuse a `typeId` for a different model — that causes hard-to-detect corruption.
/// - Keep a single source of truth for assigned typeIds (migration_notes.md) to avoid collisions.
///
/// Error handling strategy (recommended):
/// - Opening a corrupted box will throw. Recommended approaches:
///   1. Attempt recovery: catch the exception at the call site, backup the corrupted file, then try `Hive.deleteBoxFromDisk(boxName)` and re-open an empty box.
///   2. Surface a clear error to the user and provide an export/backup option if possible before deleting data.
/// - This initializer does *not* attempt recovery automatically; perform recovery where you call `initialize()` so the app can decide (e.g., show UI, log to crash reporting).
class HiveInitializer {
  /// List of all module initializers.
  ///
  /// To add a new module, create a HiveModuleInitializer implementation
  /// and add it to this list.
  static final List<HiveModuleInitializer> _moduleInitializers = [
    goal_tracker.GoalTrackerHiveInitializer(),
    travel_tracker.TravelTrackerHiveInitializer(),
    investment_planner.InvestmentPlannerHiveInitializer(),
    retirement_planner.RetirementPlannerHiveInitializer(),
    backup.BackupHiveInitializer(),
    AppPreferencesHiveInitializer(),
  ];

  /// Initializes Hive for the app and returns goal, milestone, and task boxes.
  ///
  /// - Initializes Hive Flutter bindings.
  /// - Registers all adapters via module initializers.
  /// - Opens all boxes via module initializers.
  /// - Returns goal tracker boxes for backward compatibility.
  /// - Must be awaited before DI setup and `runApp`.
  static Future<HiveBoxes> initialize() async {
    // Initialize Hive Flutter bindings. This must be called before any Hive operations.
    await Hive.initFlutter();

    // Register all adapters from all modules
    for (final initializer in _moduleInitializers) {
      await initializer.registerAdapters();
    }

    // Open all boxes from all modules
    for (final initializer in _moduleInitializers) {
      await initializer.openBoxes();
    }

    // Return goal tracker boxes for backward compatibility
    // (Some code may still depend on these being returned)
    var goalsBox = Hive.box<GoalModel>(goalBoxName);
    var milestonesBox = Hive.box<MilestoneModel>(milestoneBoxName);
    var tasksBox = Hive.box<TaskModel>(taskBoxName);
    var habitsBox = Hive.box<HabitModel>(habitBoxName);
    var habitCompletionsBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);

    // // -------------------------------------------------------------------------
    // // Debug print section (for developer visibility)
    // // -------------------------------------------------------------------------
    // print('\n========== Hive Boxes Initialized ==========');

    // // ---- Goals Box ----
    // print('\n Goals Box (${goalsBox.length} entries)');
    // if (goalsBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in goalsBox.keys) {
    //     final goal = goalsBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name       : ${goal?.name}');
    //     print('    • Description: ${goal?.description}');
    //     print('    • TargetDate : ${goal?.targetDate}');
    //     print('    • Context    : ${goal?.context}');
    //     print('    • Completed  : ${goal?.isCompleted}');
    //   }
    // }

    // // ---- Milestones Box ----
    // print('\n Milestones Box (${milestonesBox.length} entries)');
    // if (milestonesBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in milestonesBox.keys) {
    //     final ms = milestonesBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name         : ${ms?.name}');
    //     print('    • Description  : ${ms?.description}');
    //     print('    • PlannedValue : ${ms?.plannedValue}');
    //     print('    • ActualValue  : ${ms?.actualValue}');
    //     print('    • TargetDate   : ${ms?.targetDate}');
    //     print('    • GoalId       : ${ms?.goalId}');
    //   }
    // }

    // // ---- Tasks Box ----
    // print('\n Tasks Box (${tasksBox.length} entries)');
    // if (tasksBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in tasksBox.keys) {
    //     final task = tasksBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name        : ${task?.name}');
    //     print('    • TargetDate  : ${task?.targetDate}');
    //     print('    • MilestoneId : ${task?.milestoneId}');
    //     print('    • GoalId      : ${task?.goalId}');
    //     print('    • Status      : ${task?.status}');
    //   }
    // }

    // print('===========================================\n');

    return HiveBoxes(
      goalsBox: goalsBox,
      milestonesBox: milestonesBox,
      tasksBox: tasksBox,
      habitsBox: habitsBox,
      habitCompletionsBox: habitCompletionsBox,
    );
  }
}

/// Simple container class holding all opened Hive boxes.
///
/// Returned by [HiveInitializer.initialize] for easy dependency injection.
///
/// Example usage:
/// ```dart
/// final boxes = await HiveInitializer.initialize();
/// final goalBox = boxes.goalsBox;
/// final milestoneBox = boxes.milestonesBox;
/// final taskBox = boxes.tasksBox;
/// ```
class HiveBoxes {
  final Box<GoalModel> goalsBox;
  final Box<MilestoneModel> milestonesBox;
  final Box<TaskModel> tasksBox;
  final Box<HabitModel> habitsBox;
  final Box<HabitCompletionModel> habitCompletionsBox;

  HiveBoxes({
    required this.goalsBox,
    required this.milestonesBox,
    required this.tasksBox,
    required this.habitsBox,
    required this.habitCompletionsBox,
  });
}
