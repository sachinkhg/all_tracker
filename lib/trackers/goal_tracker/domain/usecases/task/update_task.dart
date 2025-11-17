/*
  purpose:
    - Encapsulates the "Update Task" use case in the domain layer.
    - Defines a single, testable action responsible for updating an existing [Task]
      via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a task is edited.
    - Accepts a [Task] domain entity with updated fields.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/task.dart';
import '../../repositories/task_repository.dart';

/// Use case class responsible for updating an existing [Task].
class UpdateTask {
  final TaskRepository repository;
  UpdateTask(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(Task task) async => repository.updateTask(task);
}

