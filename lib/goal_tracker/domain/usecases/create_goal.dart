import '../entities/goal.dart';
import '../repositories/goal_repository.dart';


// Use case: create a new goal
class CreateGoal {
final GoalRepository repository;
CreateGoal(this.repository);


Future<void> call(Goal goal) async => repository.createGoal(goal);
}