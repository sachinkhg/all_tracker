import '../entities/goal.dart';


// Abstract repository interface for Goal operations
abstract class GoalRepository {
Future<List<Goal>> getAllGoals();
Future<Goal?> getGoalById(String id);
Future<void> createGoal(Goal goal);
Future<void> updateGoal(Goal goal);
Future<void> deleteGoal(String id);
}