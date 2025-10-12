/*
  purpose:
    - Encapsulates the "Delete Task" use case in the domain layer.
    - Defines a single, testable action responsible for removing a [Task]
      via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a task is deleted.
    - Accepts a task ID and removes the corresponding task from storage.
    - Delegates deletion responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/task_repository.dart';

/// Use case class responsible for deleting a [Task] by its ID.
class DeleteTask {
  final TaskRepository repository;
  DeleteTask(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteTask(id);
}

