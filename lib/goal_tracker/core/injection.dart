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

import '../data/datasources/habit_local_data_source.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/models/habit_model.dart';
import '../domain/usecases/habit/create_habit.dart';
import '../domain/usecases/habit/get_all_habits.dart';
import '../domain/usecases/habit/get_habit_by_id.dart';
import '../domain/usecases/habit/get_habits_by_milestone_id.dart';
import '../domain/usecases/habit/update_habit.dart';
import '../domain/usecases/habit/delete_habit.dart';
import '../presentation/bloc/habit_cubit.dart';

import '../data/datasources/habit_completion_local_data_source.dart';
import '../data/repositories/habit_completion_repository_impl.dart';
import '../data/models/habit_completion_model.dart';
import '../domain/usecases/habit_completion/create_completion.dart';
import '../domain/usecases/habit_completion/get_all_completions.dart';
import '../domain/usecases/habit_completion/get_completions_by_habit_id.dart';
import '../domain/usecases/habit_completion/get_completions_by_date_range.dart';
import '../domain/usecases/habit_completion/delete_completion.dart';
import '../domain/usecases/habit_completion/toggle_completion_for_date.dart';
import '../presentation/bloc/habit_completion_cubit.dart';

import 'constants.dart';
import 'view_preferences_service.dart';
import 'filter_preferences_service.dart';
import 'sort_preferences_service.dart';

// Backup feature imports
import '../features/backup/core/encryption_service.dart';
import '../features/backup/core/device_info_service.dart';
import '../features/backup/data/datasources/google_auth_datasource.dart';
import '../features/backup/data/datasources/drive_api_client.dart';
import '../features/backup/data/datasources/backup_metadata_local_datasource.dart';
import '../features/backup/data/services/backup_builder_service.dart';
import '../features/backup/data/repositories/backup_repository_impl.dart';
import '../features/backup/data/models/backup_metadata_model.dart';
import '../features/backup/domain/usecases/create_backup.dart';
import '../features/backup/domain/usecases/list_backups.dart';
import '../features/backup/domain/usecases/restore_backup.dart';
import '../features/backup/domain/usecases/delete_backup.dart';
import '../features/backup/core/backup_preferences_service.dart';
import '../features/backup/core/backup_scheduler_service.dart';
import '../features/backup/presentation/cubit/backup_cubit.dart';

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

/// Singleton instance of SortPreferencesService.
/// 
/// Shared across all cubits to manage sort preferences.
/// Created lazily on first access.
SortPreferencesService? _sortPreferencesService;

SortPreferencesService getSortPreferencesService() {
  _sortPreferencesService ??= SortPreferencesService();
  return _sortPreferencesService!;
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
  final Box<MilestoneModel> milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  // Local data source: thin adapter over Hive Box.
  // - This is a lightweight object that holds a reference to the opened box.
  // - It does not itself open the box here to avoid double-initialization and to keep startup ordering explicit.
  final local = GoalLocalDataSourceImpl(box);
  final milestoneLocal = MilestoneLocalDataSourceImpl(milestoneBox);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  // Repository composes the local data source.
  // - If the repository needed both local and remote data sources, we would construct both above and pass them in here.
  // - Keep repositories thin: orchestration and local/remote decision logic belongs here.
  final repo = GoalRepositoryImpl(local);
  final milestoneRepo = MilestoneRepositoryImpl(milestoneLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  // Use-cases are simple wrappers over repository methods. They are cheap to create and stateless;
  // creating them directly is fine and keeps testability straightforward.
  final getAll = GetAllGoals(repo);
  final create = CreateGoal(repo);
  final update = UpdateGoal(repo);
  final delete = DeleteGoal(repo);
  final getAllMilestones = GetAllMilestones(milestoneRepo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  // Presentation layer (Cubit) depends on use-cases and ViewPreferencesService.
  // - Consider registering Cubits via `registerFactory` in a DI container so each consumer receives a fresh instance.
  // - In this manual wiring approach we return a ready-to-use instance; callers (e.g., the UI) are responsible for disposing it.
  final viewPrefsService = getViewPreferencesService();
  final filterPrefsService = getFilterPreferencesService();
  final sortPrefsService = getSortPreferencesService();
  
  return GoalCubit(
    getAll: getAll, 
    create: create, 
    update: update, 
    delete: delete, 
    getAllMilestones: getAllMilestones,
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
    sortPreferencesService: sortPrefsService,
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
  final sortPrefsService = getSortPreferencesService();
  
  return MilestoneCubit(
    getAll: getAll,
    getById: getById,
    getByGoalId: getByGoalId,
    create: create,
    update: update,
    delete: delete,
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
    sortPreferencesService: sortPrefsService,
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
  final sortPrefsService = getSortPreferencesService();
  
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
    sortPreferencesService: sortPrefsService,
  );
}

/// Factory that constructs a fully-wired [HabitCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
HabitCubit createHabitCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  final Box<HabitModel> box = Hive.box<HabitModel>(habitBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = HabitLocalDataSourceImpl(habitBox: box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = HabitRepositoryImpl(localDataSource: local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllHabits(repository: repo);
  final getById = GetHabitById(repository: repo);
  final getByMilestoneId = GetHabitsByMilestoneId(repository: repo);
  final create = CreateHabit(repository: repo);
  final update = UpdateHabit(repository: repo);
  final delete = DeleteHabit(repository: repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  final viewPrefsService = getViewPreferencesService();
  final filterPrefsService = getFilterPreferencesService();
  final sortPrefsService = getSortPreferencesService();
  
  // Get milestone repository for auto-assigning goalId
  final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
  final milestoneLocal = MilestoneLocalDataSourceImpl(milestoneBox);
  final milestoneRepo = MilestoneRepositoryImpl(milestoneLocal);
  
  return HabitCubit(
    getAll: getAll,
    getById: getById,
    getByMilestoneId: getByMilestoneId,
    create: create,
    update: update,
    delete: delete,
    milestoneRepository: milestoneRepo,
    viewPreferencesService: viewPrefsService,
    filterPreferencesService: filterPrefsService,
    sortPreferencesService: sortPrefsService,
  );
}

/// Factory that constructs a fully-wired [HabitCompletionCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
HabitCompletionCubit createHabitCompletionCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  final Box<HabitCompletionModel> completionBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);
  final Box<HabitModel> habitBox = Hive.box<HabitModel>(habitBoxName);
  final Box<MilestoneModel> milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final completionLocal = HabitCompletionLocalDataSourceImpl(completionBox: completionBox);
  final habitLocal = HabitLocalDataSourceImpl(habitBox: habitBox);
  final milestoneLocal = MilestoneLocalDataSourceImpl(milestoneBox);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final completionRepo = HabitCompletionRepositoryImpl(localDataSource: completionLocal);
  final habitRepo = HabitRepositoryImpl(localDataSource: habitLocal);
  final milestoneRepo = MilestoneRepositoryImpl(milestoneLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAllCompletions = GetAllCompletions(repository: completionRepo);
  final getCompletionsByHabitId = GetCompletionsByHabitId(repository: completionRepo);
  final getCompletionsByDateRange = GetCompletionsByDateRange(repository: completionRepo);
  final createCompletion = CreateCompletion(repository: completionRepo);
  final deleteCompletion = DeleteCompletion(repository: completionRepo);
  final toggleCompletion = ToggleCompletionForDate(
    completionRepository: completionRepo,
    habitRepository: habitRepo,
    milestoneRepository: milestoneRepo,
  );

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return HabitCompletionCubit(
    getAllCompletions: getAllCompletions,
    getCompletionsByHabitId: getCompletionsByHabitId,
    getCompletionsByDateRange: getCompletionsByDateRange,
    createCompletion: createCompletion,
    deleteCompletion: deleteCompletion,
    toggleCompletion: toggleCompletion,
  );
}

/// ---------------------------------------------------------------------------
/// Backup wiring: factory that constructs the backup repository and use cases.
///
/// Notes:
/// - Assumes the Hive backup metadata box has already been opened.
/// - Wires up the complete backup feature dependency graph:
///   Data sources → Services → Repository → Use cases
/// - The BackupCubit (presentation layer) can be created separately
///   once it's implemented.
/// ---------------------------------------------------------------------------

/// Create the backup repository with all dependencies.
BackupRepositoryImpl createBackupRepository() {
  // Ensure Hive.box<BackupMetadataModel>(backupMetadataBoxName) is opened beforehand
  final Box<BackupMetadataModel> backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);

  // ---------------------------------------------------------------------------
  // Data sources
  // ---------------------------------------------------------------------------
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final backupMetadataLocal = BackupMetadataLocalDataSourceImpl(backupBox);

  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  final backupBuilder = BackupBuilderService();

  // ---------------------------------------------------------------------------
  // Repository
  // ---------------------------------------------------------------------------
  return BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: backupMetadataLocal,
    deviceInfoService: deviceInfoService,
  );
}

/// Create all backup use cases.
///
/// Returns a map of use cases keyed by name for easy access.
Map<String, dynamic> createBackupUseCases() {
  final repository = createBackupRepository();

  return {
    'createBackup': CreateBackup(repository),
    'listBackups': ListBackups(repository),
    'restoreBackup': RestoreBackup(repository),
    'deleteBackup': DeleteBackup(repository),
    'repository': repository, // Also provide repository for progress stream access
  };
}

/// Create a fully-wired BackupCubit instance.
///
/// This factory function wires up all dependencies for the backup feature:
/// - Services (encryption, device info, preferences)
/// - Data sources (Google Auth, Drive API, local metadata storage)
/// - Repository (orchestrates backup operations)
/// - Use cases (single-responsibility operations)
/// - Cubit (state management)
BackupCubit createBackupCubit() {
  // Services
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final backupPrefsService = BackupPreferencesService();
  
  // Data sources
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  
  final backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);
  final metadataDataSource = BackupMetadataLocalDataSourceImpl(backupBox);
  
  // Backup builder service
  final backupBuilder = BackupBuilderService();
  
  // Repository
  final repository = BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: metadataDataSource,
    deviceInfoService: deviceInfoService,
  );
  
  // Use cases
  final createBackup = CreateBackup(repository);
  final listBackups = ListBackups(repository);
  final restoreBackup = RestoreBackup(repository);
  final deleteBackup = DeleteBackup(repository);
  
  // Cubit
  return BackupCubit(
    createBackup: createBackup,
    listBackups: listBackups,
    restoreBackup: restoreBackup,
    deleteBackup: deleteBackup,
    preferencesService: backupPrefsService,
    googleAuth: googleAuth,
  );
}

/// Create a BackupSchedulerService instance for automatic backups.
///
/// This service checks if automatic backups should run and executes them
/// when enabled and the 24-hour interval has passed.
BackupSchedulerService createBackupSchedulerService() {
  final backupPrefsService = BackupPreferencesService();
  
  // Create repository and use case for backup creation
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  final backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);
  final metadataDataSource = BackupMetadataLocalDataSourceImpl(backupBox);
  final backupBuilder = BackupBuilderService();
  
  final repository = BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: metadataDataSource,
    deviceInfoService: deviceInfoService,
  );
  
  final createBackup = CreateBackup(repository);
  
  return BackupSchedulerService(
    preferencesService: backupPrefsService,
    createBackupUseCase: createBackup,
    googleAuth: googleAuth,
  );
}
