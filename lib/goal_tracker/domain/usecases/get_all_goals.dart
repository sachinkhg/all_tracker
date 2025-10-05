import '../entities/goal.dart';
import '../repositories/goal_repository.dart';


// Use case: fetch all goals
class GetAllGoals {
final GoalRepository repository;
GetAllGoals(this.repository);


Future<List<Goal>> call() async => repository.getAllGoals();
}