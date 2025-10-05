import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_data_source.dart';
import '../models/goal_model.dart';


// Repository implementation bridging domain layer with data source
class GoalRepositoryImpl implements GoalRepository {
final GoalLocalDataSource local;
GoalRepositoryImpl(this.local);


@override
Future<void> createGoal(Goal goal) async {
final model = GoalModel.fromEntity(goal);
await local.createGoal(model);
}


@override
Future<void> deleteGoal(String id) async {
await local.deleteGoal(id);
}


@override
Future<List<Goal>> getAllGoals() async {
final models = await local.getAllGoals();
return models.map((m) => m.toEntity()).toList();
}


@override
Future<Goal?> getGoalById(String id) async {
final model = await local.getGoalById(id);
return model?.toEntity();
}


@override
Future<void> updateGoal(Goal goal) async {
final model = GoalModel.fromEntity(goal);
await local.updateGoal(model);
}
}