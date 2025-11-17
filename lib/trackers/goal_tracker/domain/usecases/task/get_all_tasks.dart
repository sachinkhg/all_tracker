/*
  purpose:
    - Encapsulates the "Get All Tasks" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving all [Task]
      entities via the [TaskRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when loading all tasks.
    - Returns a list of all persisted tasks.
    - Delegates retrieval responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [TaskRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/task.dart';
import '../../repositories/task_repository.dart';

/// Use case class responsible for retrieving all [Task] entities.
class GetAllTasks {
  final TaskRepository repository;
  GetAllTasks(this.repository);

  /// Executes the get operation asynchronously.
  Future<List<Task>> call() async => repository.getAllTasks();
}

