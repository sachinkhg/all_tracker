/*
  purpose:
    - Encapsulates the "Get Tasks By Milestone ID" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving all [Task] entities
      associated with a specific milestone via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when loading tasks for a milestone.
    - Returns a list of tasks belonging to the specified milestone.
    - Delegates retrieval responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/task.dart';
import '../../repositories/task_repository.dart';

/// Use case class responsible for retrieving all [Task] entities for a milestone.
class GetTasksByMilestoneId {
  final TaskRepository repository;
  GetTasksByMilestoneId(this.repository);

  /// Executes the get operation asynchronously.
  Future<List<Task>> call(String milestoneId) async =>
      repository.getTasksByMilestoneId(milestoneId);
}

