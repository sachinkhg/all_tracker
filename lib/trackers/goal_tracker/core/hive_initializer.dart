import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/goal_model.dart';
import '../data/models/milestone_model.dart';
import '../data/models/task_model.dart';
import '../data/models/habit_model.dart';
import '../data/models/habit_completion_model.dart';
import '../core/constants.dart';

/// Hive initializer for the goal_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the goal_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class GoalTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register GoalModel adapter (TypeId: 0)
    final goalAdapterId = GoalModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(goalAdapterId)) {
      Hive.registerAdapter(GoalModelAdapter());
    }

    // Register MilestoneModel adapter (TypeId: 1)
    final milestoneAdapterId = MilestoneModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(milestoneAdapterId)) {
      Hive.registerAdapter(MilestoneModelAdapter());
    }

    // Register TaskModel adapter (TypeId: 2)
    final taskAdapterId = TaskModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(taskAdapterId)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    // Register HabitModel adapter (TypeId: 3)
    final habitAdapterId = HabitModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(habitAdapterId)) {
      Hive.registerAdapter(HabitModelAdapter());
    }

    // Register HabitCompletionModel adapter (TypeId: 4)
    final habitCompletionAdapterId = HabitCompletionModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(habitCompletionAdapterId)) {
      Hive.registerAdapter(HabitCompletionModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open goal tracker boxes
    await Hive.openBox<GoalModel>(goalBoxName);
    await Hive.openBox<MilestoneModel>(milestoneBoxName);
    await Hive.openBox<TaskModel>(taskBoxName);
    await Hive.openBox<HabitModel>(habitBoxName);
    await Hive.openBox<HabitCompletionModel>(habitCompletionBoxName);
  }
}

