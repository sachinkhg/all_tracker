// lib/goal_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.
// The rest of the app (presentation) will call createGoalCubit() and remain
// unaware of data-layer implementation details.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/goal_local_data_source.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../data/models/goal_model.dart';
import '../domain/usecases/create_goal.dart';
import '../domain/usecases/get_all_goals.dart';
import '../domain/usecases/update_goal.dart';
import '../domain/usecases/delete_goal.dart';
import '../presentation/bloc/goal_cubit.dart';
import 'constants.dart';

/// Using the same literal used elsewhere to avoid cross-file import problems.
/// If you already have a central constant (recommended), you can import that instead.

/// Factory that constructs a fully-wired GoalCubit.
GoalCubit createGoalCubit() {
  // Hive.box must be already opened (open in main.dart)
  final Box<GoalModel> box = Hive.box<GoalModel>(goalBoxName);

  // Data layer
  final local = GoalLocalDataSourceImpl(box); 

  // Repository layer
  final repo = GoalRepositoryImpl(local);

  // Use-cases (domain)
  final getAll = GetAllGoals(repo);
  final create = CreateGoal(repo);
  final update = UpdateGoal(repo);
  final delete = DeleteGoal(repo);

  // Presentation
  return GoalCubit(getAll: getAll, create: create, update: update, delete: delete);
}
