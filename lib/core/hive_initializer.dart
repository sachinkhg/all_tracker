import 'package:get_it/get_it.dart';
import '../goal_tracker/di/service_locator.dart';
import '../goal_tracker/domain/usecases/goal_usecases.dart';
import '../goal_tracker/util/dummy_goals.dart';
import 'service_locator.dart'; // global initAppDI()

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
            // Add dummy data if empty
            final getGoals = sl<GetGoals>();
            final addGoal = sl<AddGoal>();
            final goals = await getGoals();
            if (goals.isEmpty) {
              for (final goal in generateDummyGoals()) {
                await addGoal(goal);
              }
            }
            break;
        
        // 🔜 case TrackerType.habitTracker:
        //   await initHabitTrackerDI(sl);
        //   break;
      }

      _initializedTrackers.add(tracker);
    }
  }
}
