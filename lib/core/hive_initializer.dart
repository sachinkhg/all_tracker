// ignore_for_file: avoid_print

import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:get_it/get_it.dart';
import '../goal_tracker/data/models/milestone_model.dart';
import '../goal_tracker/di/service_locator.dart';
import '../goal_tracker/domain/entities/goal.dart';
import '../goal_tracker/domain/entities/milestone.dart';
import '../goal_tracker/domain/usecases/goal_usecases.dart';
import '../goal_tracker/domain/usecases/milestone_usecases.dart';
import '../goal_tracker/util/dummy_goals.dart';
import 'service_locator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

// Enum to identify which tracker to initialize
enum TrackerType {
  goalManagement,
  // Add other trackers here: habitTracker, fitnessTracker, etc.
}

class HiveInitializer {
  static bool _globalInitialized = false;
  static final Set<TrackerType> _initializedTrackers = {};

  static Future<void> initialize({required TrackerType tracker}) async {
    // 1️⃣ Global Hive init (runs only once)
    if (!_globalInitialized) {
      await initAppDI();
      _globalInitialized = true;
    }

    // 2️⃣ Feature-specific init (runs once per tracker)
    if (!_initializedTrackers.contains(tracker)) {
      final sl = GetIt.instance;

      switch (tracker) {
        case TrackerType.goalManagement:
          await initGoalManagementDI(sl);

          // Clear old goal box data (for migration/dev) before loading dummy data
          // var goalBox = await Hive.openBox<GoalModel>('goals');
          // await goalBox.clear();
          
          
          // Add dummy data if empty
          final getGoals = sl<GetGoals>();
          final addGoal = sl<AddGoal>();
          final goals = await getGoals();
          if (goals.isEmpty) {
            // Generate dummy data map with goals and milestones
            final dummyData = generateDummyGoalsAndMilestones();
            final List<Goal> dummyGoals = dummyData['goals'] as List<Goal>;
            final List<Milestone> dummyMilestones = dummyData['milestones'] as List<Milestone>;

            // Add milestones first (assuming you have addMilestone usecase)
            final addMilestone = sl<AddMilestone>(); // Adjust according to your DI setup
            for (final milestone in dummyMilestones) {
              await addMilestone(milestone);
            }

            // Now add goals with milestoneIds referencing the saved milestones
            for (final goal in dummyGoals) {
              await addGoal(goal);
            }
          }
          break;
      }
      _initializedTrackers.add(tracker);
      // printHiveDir();
      // printMilestoneBox();
      // printGoalBox();
    }
  }
  
}

void printHiveDir() async {
  final dir = await getApplicationDocumentsDirectory();
  print('Hive files location: ${dir.path}');
}



void printMilestoneBox() async {
  var box = await Hive.openBox<MilestoneModel>('milestones'); // Replace with your actual box name and type

  print('Printing all milestones in box:');
  for (var key in box.keys) {
    var milestone = box.get(key);
    print('Key: $key, Milestone: ${milestone?.title}, targetDate: ${milestone?.targetDate}');
  }
}

void printGoalBox() async {
  var goalBox = await Hive.openBox<GoalModel>('goals'); // Your goal box
  var milestoneBox = await Hive.openBox<MilestoneModel>('milestones'); // Your milestone box

  print('Printing all goals and their milestones:');
  for (var key in goalBox.keys) {
    var goal = goalBox.get(key);
    if (goal == null) continue;

    print('Goal Key: $key');

    if (goal.milestoneIds.isEmpty) {
      print('  No milestones available');
    } else {
      for (var milestoneId in goal.milestoneIds) {
        var milestone = milestoneBox.get(milestoneId);
        if (milestone != null) {
          print('  Milestone: ${milestone.id}, targetDate: ${milestone.targetDate}');
        } else {
          print('  Milestone ID $milestoneId not found in milestone box');
        }
      }
    }
  }
}
