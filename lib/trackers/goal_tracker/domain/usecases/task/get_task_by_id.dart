/*
  purpose:
    - Encapsulates the "Get Task By ID" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving a specific [Task]
      entity by its unique identifier via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when loading a specific task.
    - Returns the task matching the provided ID, or null if not found.
    - Delegates retrieval responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/task.dart';
import '../../repositories/task_repository.dart';

/// Use case class responsible for retrieving a [Task] by its ID.
class GetTaskById {
  final TaskRepository repository;
  GetTaskById(this.repository);

  /// Executes the get operation asynchronously.
  Future<Task?> call(String id) async => repository.getTaskById(id);
}

