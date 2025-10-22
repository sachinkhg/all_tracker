// lib/goal_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.
// The rest of the app (presentation) will call createGoalCubit() and remain
// unaware of data-layer implementation details.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/goal_local_data_source.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../data/models/goal_model.dart';
import '../domain/usecases/goal/create_goal.dart';
import '../domain/usecases/goal/get_all_goals.dart';
import '../domain/usecases/goal/update_goal.dart';
import '../domain/usecases/goal/delete_goal.dart';
import '../presentation/bloc/goal_cubit.dart';

import '../data/datasources/milestone_local_data_source.dart';
import '../data/repositories/milestone_repository_impl.dart';
import '../data/models/milestone_model.dart';
import '../domain/usecases/milestone/create_milestone.dart';
import '../domain/usecases/milestone/get_all_milestones.dart';
import '../domain/usecases/milestone/get_milestone_by_id.dart';
import '../domain/usecases/milestone/get_milestones_by_goal_id.dart';
import '../domain/usecases/milestone/update_milestone.dart';
import '../domain/usecases/milestone/delete_milestone.dart';
import '../presentation/bloc/milestone_cubit.dart';

import '../data/datasources/task_local_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/models/task_model.dart';
import '../domain/usecases/task/create_task.dart';
import '../domain/usecases/task/get_all_tasks.dart';
import '../domain/usecases/task/get_task_by_id.dart';
import '../domain/usecases/task/get_tasks_by_milestone_id.dart';
import '../domain/usecases/task/update_task.dart';
import '../domain/usecases/task/delete_task.dart';
import '../presentation/bloc/task_cubit.dart';

import 'constants.dart';
import 'view_preferences_service.dart';
import 'filter_preferences_service.dart';

/// Singleton instance of ViewPreferencesService.
/// 
/// Shared across all cubits to manage view field preferences.
/// Created lazily on first access.
ViewPreferencesService? _viewPreferencesService;

ViewPreferencesService getViewPreferencesService() {
  _viewPreferencesService ??= ViewPreferencesService();
  return _viewPreferencesService!;
}

/// Singleton instance of FilterPreferencesService.
/// 
/// Shared across all cubits to manage filter preferences.
/// Created lazily on first access.
FilterPreferencesService? _filterPreferencesService;

FilterPreferencesService getFilterPreferencesService() {
  _filterPreferencesService ??= FilterPreferencesService();
  return _filterPreferencesService!;
}

/// Composition root for the goal_tracker feature.
///
/// Purpose:
/// - Centralizes wiring for the feature: data sources → repositories → use-cases → presentation (cubits/blocs).
/// - Keeps the rest of the app ignorant of concrete implementations (use dependency inversion at the boundary).
///
/// How DI is organized in this project:
/// - Module-level registrars (feature folders) are responsible for wiring dependencies relevant to that feature.
/// - App-level singletons (if any) live in a top-level composition root (e.g., app/injection.dart) and are shared across features.
/// - This file acts as the *module-level* composition root for the `goal_tracker` feature.
///
/// Registration order and rationale:
/// 1. **Data sources** (e.g., local/remote adapters) — they are the lowest-level dependencies and may open resources (DB boxes, sockets).
/// 2. **Repositories** — compose one or more data sources and implement domain-facing contracts.
/// 3. **Use-cases** — simple, single-responsibility domain operations that depend on repositories.
/// 4. **Presentation (Cubits/Blocs/Providers)** — depend on use-cases. Presentation code should only know about use-case interfaces.
///
/// Why order matters:
/// - Higher-level objects depend on lower-level objects. Constructing in this order ensures all dependencies are available when needed.
/// - Side-effects (opening DBs, starting streams) must happen before consumers expect them.
///
/// Overriding for tests or feature toggles:
/// - Tests should construct the same graph but pass test doubles (mocks/fakes) at the appropriate boundary:
///   * To replace a data source: construct a repository with a mocked data source and then the use-cases/cubit with that repository.
///   * To replace a repository: construct use-cases with the mocked repo, then cubit with those use-cases.
///
/// - If using a DI container (get_it, injectable, etc.), prefer:
///   * `registerSingleton<T>(instance)` for true singletons that should be eagerly available and shared globally.
///   * `registerLazySingleton<T>(factory)` for singletons that you want created on first use (useful when creation is expensive or has side-effects).
///   * `registerFactory<T>(() => T())` for transient dependencies where each consumer must get a fresh instance (typical for Cubits/Blocs).
///
/// - In tests:
///   * Use `registerSingleton<T>(mock)` to force the container to return your mock instead of the real implementation.
///   * Use `registerFactory` sparingly in tests unless you want a new mocked instance each time.
///
/// Notes about side-effects and lifecycle:
/// - Opening Hive boxes, initializing databases, or starting listeners should happen outside this file (e.g., in `main.dart`)
///   before calling `createGoalCubit()` so the returned objects find resources ready. See `main.dart` for startup ordering.
/// - If a data source opens resources lazily, document it clearly where that resource is opened.
///
/// Keep comments developer-focused: this file documents *how* wiring happens and *where* to override behavior for tests.
/// Do not change runtime logic here — this file only builds and returns a fully-wired GoalCubit instance.

/// Factory that constructs a fully-wired [GoalCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive box named [goalBoxName] has already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used). Tests can bypass this by constructing
///   the same graph but substituting mocks/fakes at the appropriate constructor boundaries.
///
/// Overriding for tests:
/// - Preferred approach for unit-tests: don't call this function. Instead, construct the [GoalCubit] directly in test,
///   passing mocked use-case instances (or pass mocked repositories into real use-cases) so you control dependencies precisely.
/// - If you adopt a DI container later, expose a test-only registration helper where you can `registerSingleton` test doubles
///   before resolving the cubit. This file is neutral to that decision — it shows the concrete construction order.
GoalCubit createGoalCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // Side-effect risk: calling Hive.box(...) when the box is not open will throw.
  // Opening boxes is an app-level startup concern and should be performed before calling this factory.
  final Box<GoalModel> box = Hive.box<GoalModel>(goalBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  // Local data source: thin adapter over Hive Box.
  // - This is a lightweight object that holds a reference to the opened box.
  // - It does not itself open the box here to avoid double-initialization and to keep startup ordering explicit.
  final local = GoalLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  // Repository composes the local data source.
  // - If the repository needed both local and remote data sources, we would construct both above and pass them in here.
  // - Keep repositories thin: orchestration and local/remote decision logic belongs here.
  final repo = GoalRepositoryImpl(local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  // Use-cases are simple wrappers over repository methods. They are cheap to create and stateless;
  // creating them directly is fine and keeps testability straightforward.
  final getAll = GetAllGoals(repo);
  final create = CreateGoal(repo);
  final update = UpdateGoal(repo);
  final delete = DeleteGoal(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  // Presentation layer (Cubit) depends on use-cases and ViewPreferencesService.
  // - Consider registering Cubits via `registerFactory` in a DI container so each consumer receives a fresh instance.
  // - In this manual wiring approach we return a ready-to-use instance; callers (e.g., the UI) are responsible for disposing it.
  final viewPrefsService = getViewPreferencesService();
  final filterPrefsService = getFilterPreferencesService();
  
  return GoalCubit(
    getAll: getAll, 
    create: create, 
    update: update, 
    delete: delete, 
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
  );
}

/// ---------------------------------------------------------------------------
/// Milestone wiring: parallel factory that constructs a fully-wired [MilestoneCubit].
///
/// Notes:
/// - Assumes the Hive box named [milestoneBoxName] has already been opened.
/// - Mirrors the Goal wiring pattern: local datasource → repository → use-cases → cubit.
/// - Tests should construct their own graph and inject mocks as required.
/// ---------------------------------------------------------------------------
MilestoneCubit createMilestoneCubit() {
  // Ensure Hive.box<MilestoneModel>(milestoneBoxName) is opened beforehand (main.dart).
  final Box<MilestoneModel> box = Hive.box<MilestoneModel>(milestoneBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = MilestoneLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = MilestoneRepositoryImpl(local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllMilestones(repo);
  final getById = GetMilestoneById(repo);
  final getByGoalId = GetMilestonesByGoalId(repo);
  final create = CreateMilestone(repo);
  final update = UpdateMilestone(repo);
  final delete = DeleteMilestone(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  final viewPrefsService = getViewPreferencesService();
  final filterPrefsService = getFilterPreferencesService();
  
  return MilestoneCubit(
    getAll: getAll,
    getById: getById,
    getByGoalId: getByGoalId,
    create: create,
    update: update,
    delete: delete,
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
  );
}

/// ---------------------------------------------------------------------------
/// Task wiring: parallel factory that constructs a fully-wired [TaskCubit].
///
/// Notes:
/// - Assumes the Hive box named [taskBoxName] has already been opened.
/// - Mirrors the Goal and Milestone wiring pattern: local datasource → repository → use-cases → cubit.
/// - **CRITICAL**: TaskCubit requires MilestoneRepository to auto-assign goalId from milestone.
/// - Tests should construct their own graph and inject mocks as required.
/// ---------------------------------------------------------------------------
TaskCubit createTaskCubit() {
  // Ensure Hive.box<TaskModel>(taskBoxName) is opened beforehand (main.dart).
  final Box<TaskModel> box = Hive.box<TaskModel>(taskBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = TaskLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = TaskRepositoryImpl(local);

  // Task cubit needs MilestoneRepository for goalId resolution.
  // We create the milestone repository here (reusing the pattern from createMilestoneCubit).
  final Box<MilestoneModel> milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
  final milestoneLocal = MilestoneLocalDataSourceImpl(milestoneBox);
  final milestoneRepo = MilestoneRepositoryImpl(milestoneLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllTasks(repo);
  final getById = GetTaskById(repo);
  final getByMilestoneId = GetTasksByMilestoneId(repo);
  final create = CreateTask(repo);
  final update = UpdateTask(repo);
  final delete = DeleteTask(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  final viewPrefsService = getViewPreferencesService();
  final filterPrefsService = getFilterPreferencesService();
  
  return TaskCubit(
    getAll: getAll,
    getById: getById,
    getByMilestoneId: getByMilestoneId,
    create: create,
    update: update,
    delete: delete,
    milestoneRepository: milestoneRepo, // Required for goalId auto-assignment
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
  );
}
