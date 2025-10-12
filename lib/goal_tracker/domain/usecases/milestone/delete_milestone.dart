/*
  purpose:
    - Encapsulates the "Delete Milestone" operation in the domain layer.
    - Provides a clean, testable abstraction for removing milestones without
      exposing data persistence details.

  usage:
    - Invoked when user deletes a milestone from UI or cleanup logic.
*/

import '../../repositories/milestone_repository.dart';

/// Use case for deleting a milestone by its [id].
class DeleteMilestone {
  final MilestoneRepository repository;
  DeleteMilestone(this.repository);

  /// Executes the delete operation.
  Future<void> call(String id) async => repository.deleteMilestone(id);
}
