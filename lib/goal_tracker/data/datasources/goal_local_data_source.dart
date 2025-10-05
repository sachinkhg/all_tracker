import 'package:hive/hive.dart';
import '../models/goal_model.dart';


// Abstract data source for local goal storage
abstract class GoalLocalDataSource {
  Future<List<GoalModel>> getAllGoals();
  Future<GoalModel?> getGoalById(String id);
  Future<void> createGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
}


// Hive implementation of GoalLocalDataSource
class GoalLocalDataSourceImpl implements GoalLocalDataSource {
  final Box<GoalModel> box;
  GoalLocalDataSourceImpl(this.box);


  @override
  Future<void> createGoal(GoalModel goal) async {
    await box.put(goal.id, goal);
  }


  @override
  Future<void> deleteGoal(String id) async {
    await box.delete(id);
  }


  @override
  Future<GoalModel?> getGoalById(String id) async {
    return box.get(id);
  }


  @override
  Future<List<GoalModel>> getAllGoals() async {
    return box.values.toList();
  }


  @override
  Future<void> updateGoal(GoalModel goal) async {
    await box.put(goal.id, goal);
  }
}