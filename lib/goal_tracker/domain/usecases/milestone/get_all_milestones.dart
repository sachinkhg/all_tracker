/*
  purpose:
    - Retrieves all stored milestones from the domain repository.
    - Provides a simple, testable abstraction for listing all milestones
      without exposing data-layer dependencies.

  usage:
    - Invoked by application logic or Cubits to render milestone lists.
    - Returns a list of [Milestone] domain entities.

  compatibility guidance:
    - Keep read operations lightweight and domain-pure.
*/

import '../../entities/milestone.dart';
import '../../repositories/milestone_repository.dart';

/// Use case for retrieving all milestones from storage.
class GetAllMilestones {
  final MilestoneRepository repository;
  GetAllMilestones(this.repository);

  /// Executes the retrieval operation.
  Future<List<Milestone>> call() async => repository.getAllMilestones();
}
