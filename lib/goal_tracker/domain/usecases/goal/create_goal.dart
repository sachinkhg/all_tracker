// ./lib/goal_tracker/domain/usecases/create_goal.dart
/*
  purpose:
    - Encapsulates the "Create Goal" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Goal] entity
      via the [GoalRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new goal is created.
    - Accepts a [Goal] domain entity that is already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [GoalRepository].
    - Keep this use case simple and composable with other domain operations.
    - If new creation rules (e.g., validation, default context assignment) are added,
      update README and domain guidelines accordingly.
*/

import '../../entities/goal.dart';
import '../../repositories/goal_repository.dart';

/// Use case class responsible for creating a new [Goal].
///
/// Interacts with the [GoalRepository] abstraction to persist
/// the entity, ensuring separation of concerns between
/// domain logic and data persistence.
class CreateGoal {
  /// Repository providing persistence operations.
  final GoalRepository repository;

  /// Constructs the use case with the required repository dependency.
  CreateGoal(this.repository);

  /// Executes the create operation asynchronously.
  ///
  /// Delegates to [GoalRepository.createGoal] for actual persistence.
  /// Implementations of the repository must handle ID generation and
  /// validation as per domain rules.
  Future<void> call(Goal goal) async => repository.createGoal(goal);
}
