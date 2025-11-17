/*
  purpose:
    - Encapsulates the "Create Task" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Task]
      via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new task is created.
    - Accepts a [Task] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/task.dart';
import '../../repositories/task_repository.dart';

/// Use case class responsible for creating a new [Task].
class CreateTask {
  final TaskRepository repository;
  CreateTask(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(Task task) async => repository.createTask(task);
}

