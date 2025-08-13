import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../data/datasources/goal_local_data_source.dart';
import '../data/models/checklist_model.dart';
import '../data/models/task_model.dart';
import '../data/models/milestone_model.dart';
import '../data/models/goal_model.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/usecases/goal_usecases.dart';

Future<void> initGoalManagementDI(GetIt sl) async {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ChecklistModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TaskModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MilestoneModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GoalModelAdapter());

  if (!Hive.isBoxOpen('goals')) {
    await Hive.openBox<GoalModel>('goals');
  }
  final goalBox = Hive.box<GoalModel>('goals');

  sl.registerLazySingleton(() => GoalLocalDataSource(goalBox));
  sl.registerLazySingleton<GoalRepository>(() => GoalRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetGoals(sl()));
  sl.registerLazySingleton(() => GetGoalById(sl()));
  sl.registerLazySingleton(() => AddGoal(sl()));
  sl.registerLazySingleton(() => UpdateGoal(sl()));
  sl.registerLazySingleton(() => DeleteGoal(sl()));
  sl.registerLazySingleton(() => ClearAllGoals(sl()));
}
