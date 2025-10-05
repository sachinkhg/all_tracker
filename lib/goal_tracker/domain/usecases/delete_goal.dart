import '../repositories/goal_repository.dart';


// Use case: delete a goal by id
class DeleteGoal {
final GoalRepository repository;
DeleteGoal(this.repository);


Future<void> call(String id) async => repository.deleteGoal(id);
}