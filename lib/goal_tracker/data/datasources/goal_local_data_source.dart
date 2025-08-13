import 'package:hive/hive.dart';
import '../models/goal_model.dart';

class GoalLocalDataSource {
  final Box<GoalModel> goalBox;

  GoalLocalDataSource(this.goalBox);

  // Retrieve all Goals from the box
  List<GoalModel> getGoals() {
    return goalBox.values.toList();
  }

  // Get a single Goal by id
  GoalModel? getGoalById(String id) {
    return goalBox.get(id);
  }

    // Get a single Goal by id
  GoalModel? getGoalByName(String name) {
    return goalBox.get(name);
  }

  // Add a new Goal
  Future<void> addGoal(GoalModel goal) async {
    await goalBox.put(goal.id, goal);
  }

  // Update an existing Goal
  Future<void> updateGoal(GoalModel goal) async {
    await goalBox.put(goal.id, goal);
  }

  // Delete a Goal by id
  Future<void> deleteGoal(String id) async {
    await goalBox.delete(id);
  }

  // Additional utility: Clear all goals (optional)
  Future<void> clearAll() async {
    await goalBox.clear();
  }
}
