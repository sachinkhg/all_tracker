import '../entities/goal.dart';
import '../repositories/goal_repository.dart';


// Use case: fetch a single goal by id
class GetGoalById {
final GoalRepository repository;
GetGoalById(this.repository);


Future<Goal?> call(String id) async => repository.getGoalById(id);
}