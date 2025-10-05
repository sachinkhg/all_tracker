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
  // Presentation layer (Cubit) depends on use-cases.
  // - Consider registering Cubits via `registerFactory` in a DI container so each consumer receives a fresh instance.
  // - In this manual wiring approach we return a ready-to-use instance; callers (e.g., the UI) are responsible for disposing it.
  return GoalCubit(getAll: getAll, create: create, update: update, delete: delete);
}
