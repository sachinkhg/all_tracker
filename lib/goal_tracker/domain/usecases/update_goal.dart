import '../entities/goal.dart';
import '../repositories/goal_repository.dart';


// Use case: update an existing goal
class UpdateGoal {
final GoalRepository repository;
UpdateGoal(this.repository);


Future<void> call(Goal goal) async => repository.updateGoal(goal);
}