/*
  purpose:
    - Encapsulates the "Create Milestone" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Milestone]
      via the [MilestoneRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new milestone is created.
    - Accepts a [Milestone] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [MilestoneRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/milestone.dart';
import '../../repositories/milestone_repository.dart';

/// Use case class responsible for creating a new [Milestone].
class CreateMilestone {
  final MilestoneRepository repository;
  CreateMilestone(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(Milestone milestone) async =>
      repository.createMilestone(milestone);
}
