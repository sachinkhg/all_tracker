/*
  purpose:
    - Encapsulates retrieval of a single [Milestone] by its unique ID.
    - Abstracts direct repository access to improve testability and maintain
      clean separation between domain logic and data storage.

  usage:
    - Called when viewing or editing a specific milestone in the UI.
*/

import '../../entities/milestone.dart';
import '../../repositories/milestone_repository.dart';

/// Use case for retrieving a specific milestone by ID.
class GetMilestoneById {
  final MilestoneRepository repository;
  GetMilestoneById(this.repository);

  /// Executes the lookup by [id].
  Future<Milestone?> call(String id) async =>
      repository.getMilestoneById(id);
}
