// ./lib/goal_tracker/domain/usecases/get_all_goals.dart
/*
  purpose:
    - Encapsulates the "Get All Goals" domain use case, responsible for retrieving
      all [Goal] entities through the [GoalRepository].
    - Provides a clean, reusable, and testable abstraction between
      the presentation layer (e.g., Cubit/Bloc) and data access logic.

  usage:
    - Typically called when initializing the Goal list view or refreshing data.
    - Delegates retrieval responsibility to [GoalRepository.getAllGoals].
    - May later include domain-level sorting, filtering, or transformation
      without affecting the UI or repository contract.

  compatibility guidance:
    - Keep domain logic independent of UI sorting or filtering rules.
    - If additional metadata (e.g., archived goals, pagination) is introduced,
      update the domain model and adjust this use case accordingly.
    - Reflect any changes in ARCHITECTURE.md and migration_notes.md.
*/

import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

/// Use case class responsible for fetching all [Goal] entities.
///
/// Provides an abstraction layer between the UI/business logic and
/// the repository implementation, ensuring clean architecture principles.
class GetAllGoals {
  /// Repository instance for accessing goal data.
  final GoalRepository repository;

  /// Creates a [GetAllGoals] use case with the required [GoalRepository].
  GetAllGoals(this.repository);

  /// Executes the retrieval operation asynchronously.
  ///
  /// Returns a list of [Goal]s fetched from the underlying repository.
  /// The repository defines the order and filtering logic (if any).
  Future<List<Goal>> call() async => repository.getAllGoals();
}
