import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/trackers/goal_tracker/features/backup/data/models/backup_metadata_model.dart';
import 'package:all_tracker/trackers/goal_tracker/core/constants.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/investment_component_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/income_category_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/expense_category_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/income_entry_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/expense_entry_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/component_allocation_model.dart';
import 'package:all_tracker/utilities/investment_planner/data/models/investment_plan_model.dart';
import 'package:all_tracker/utilities/investment_planner/core/constants.dart';
import 'package:all_tracker/utilities/retirement_planner/data/models/retirement_plan_model.dart';
import 'package:all_tracker/utilities/retirement_planner/core/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive initializer for the app.
///
/// Responsibility:
/// - Registers all Hive TypeAdapters used by the app (so Hive can serialize/deserialize objects).
/// - Opens the necessary Hive boxes for feature modules (returns them for immediate use).
/// - Ensures schema compatibility by making adapter registrations deterministic.
///
/// Boot order:
/// - MUST be called early in app startup (before DI finalization and before `runApp`).
///   Typical place: `main()` — perform `await HiveInitializer.initialize()` before constructing the DI graph
///   so repositories/data-sources find opened boxes.
///
/// Migration guidance:
/// - When adding a new Hive model:
///   1. Create the model and its generated adapter (or manual adapter).
///   2. Assign a unique `typeId` in the adapter. Record the new typeId and a short description in `migration_notes.md`.
///   3. Register the adapter here (and add an inline comment noting the mapping: `typeId -> Model`).
/// - If changing an existing model's fields:
///   * Prefer additive changes (new nullable fields). For breaking changes, add explicit migration code and document it in `migration_notes.md`.
///   * NEVER reuse a `typeId` for a different model — that causes hard-to-detect corruption.
/// - Keep a single source of truth for assigned typeIds (a central file or `migration_notes.md`) to avoid collisions.
///
/// Error handling strategy (recommended):
/// - Opening a corrupted box will throw. Recommended approaches:
///   1. Attempt recovery: catch the exception at the call site, backup the corrupted file, then try `Hive.deleteBoxFromDisk(boxName)` and re-open an empty box.
///   2. Surface a clear error to the user and provide an export/backup option if possible before deleting data.
/// - This initializer does *not* attempt recovery automatically; perform recovery where you call `initialize()` so the app can decide (e.g., show UI, log to crash reporting).
///
/// Developer note:
/// - This file contains only wiring and adapter registration. Keep migrations and data migrations separate (e.g., a `migrations/` folder or in `migration_notes.md`).
class HiveInitializer {
  /// Initializes Hive for the app and returns goal, milestone, and task boxes.
  ///
  /// - Registers adapters if not already registered.
  /// - Opens boxes `'goals_box'`, `'milestones_box'`, and `'tasks_box'`.
  /// - Prints contents for verification.
  /// - Must be awaited before DI setup and `runApp`.
  static Future<HiveBoxes> initialize() async {
    // Initialize Hive Flutter bindings. This must be called before any Hive operations.
    await Hive.initFlutter();

    // -------------------------------------------------------------------------
    // Adapter registration
    // -------------------------------------------------------------------------
    final goalAdapterId = GoalModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(goalAdapterId)) {
      Hive.registerAdapter(GoalModelAdapter());
    }

    final milestoneAdapterId = MilestoneModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(milestoneAdapterId)) {
      Hive.registerAdapter(MilestoneModelAdapter());
    }

    final taskAdapterId = TaskModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(taskAdapterId)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    final habitAdapterId = HabitModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(habitAdapterId)) {
      Hive.registerAdapter(HabitModelAdapter());
    }

    final habitCompletionAdapterId = HabitCompletionModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(habitCompletionAdapterId)) {
      Hive.registerAdapter(HabitCompletionModelAdapter());
    }

    final backupMetadataAdapterId = BackupMetadataModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(backupMetadataAdapterId)) {
      Hive.registerAdapter(BackupMetadataModelAdapter());
    }

    // Investment Planner adapters
    // typeId: 6 -> InvestmentComponentModel
    final investmentComponentAdapterId = InvestmentComponentModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentComponentAdapterId)) {
      Hive.registerAdapter(InvestmentComponentModelAdapter());
    }

    // typeId: 7 -> IncomeCategoryModel
    final incomeCategoryAdapterId = IncomeCategoryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(incomeCategoryAdapterId)) {
      Hive.registerAdapter(IncomeCategoryModelAdapter());
    }

    // typeId: 8 -> ExpenseCategoryModel
    final expenseCategoryAdapterId = ExpenseCategoryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseCategoryAdapterId)) {
      Hive.registerAdapter(ExpenseCategoryModelAdapter());
    }

    // typeId: 9 -> InvestmentPlanModel
    final investmentPlanAdapterId = InvestmentPlanModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentPlanAdapterId)) {
      Hive.registerAdapter(InvestmentPlanModelAdapter());
    }

    // typeId: 10 -> IncomeEntryModel
    final incomeEntryAdapterId = IncomeEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(incomeEntryAdapterId)) {
      Hive.registerAdapter(IncomeEntryModelAdapter());
    }

    // typeId: 11 -> ExpenseEntryModel
    final expenseEntryAdapterId = ExpenseEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseEntryAdapterId)) {
      Hive.registerAdapter(ExpenseEntryModelAdapter());
    }

    // typeId: 12 -> ComponentAllocationModel
    final componentAllocationAdapterId = ComponentAllocationModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(componentAllocationAdapterId)) {
      Hive.registerAdapter(ComponentAllocationModelAdapter());
    }

    // Retirement Planner adapters
    // typeId: 13 -> RetirementPlanModel
    final retirementPlanAdapterId = RetirementPlanModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(retirementPlanAdapterId)) {
      Hive.registerAdapter(RetirementPlanModelAdapter());
    }

    // -------------------------------------------------------------------------
    // Box opening
    // -------------------------------------------------------------------------
    var goalsBox = await Hive.openBox<GoalModel>(goalBoxName);
    var milestonesBox = await Hive.openBox<MilestoneModel>(milestoneBoxName);
    var tasksBox = await Hive.openBox<TaskModel>(taskBoxName);
    var habitsBox = await Hive.openBox<HabitModel>(habitBoxName);
    var habitCompletionsBox = await Hive.openBox<HabitCompletionModel>(habitCompletionBoxName);
    
    // Open backup metadata box (stores backup metadata)
    await Hive.openBox<BackupMetadataModel>(backupMetadataBoxName);
    
    // Open backup preferences box (stores backup settings like retention count, auto-backup enabled, etc.)
    await Hive.openBox(backupPreferencesBoxName);
    
    // Open view preferences box (stores user view field visibility settings)
    await Hive.openBox(viewPreferencesBoxName);
    
    // Open filter preferences box (stores user filter settings)
    await Hive.openBox(filterPreferencesBoxName);
    
    // Open sort preferences box (stores user sort settings)
    await Hive.openBox(sortPreferencesBoxName);

    // Open investment planner boxes
    await Hive.openBox<InvestmentComponentModel>(investmentComponentBoxName);
    await Hive.openBox<IncomeCategoryModel>(incomeCategoryBoxName);
    await Hive.openBox<ExpenseCategoryModel>(expenseCategoryBoxName);
    await Hive.openBox<InvestmentPlanModel>(investmentPlanBoxName);

    // Open retirement planner boxes
    await Hive.openBox<RetirementPlanModel>(retirementPlanBoxName);
    await Hive.openBox(retirementPreferencesBoxName);

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
