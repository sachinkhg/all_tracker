/*
  purpose:
    - Encapsulates the "Update Milestone" operation in the domain layer.
    - Defines a clear, reusable interface for modifying existing milestones
      while keeping storage concerns abstracted behind the repository.

  usage:
    - Invoked by presentation layer components (Cubit/Bloc) when user edits
      a milestone.
*/

import '../../entities/milestone.dart';
import '../../repositories/milestone_repository.dart';

/// Use case for updating an existing [Milestone].
class UpdateMilestone {
  final MilestoneRepository repository;
  UpdateMilestone(this.repository);

  /// Executes the update operation.
  Future<void> call(Milestone milestone) async =>
      repository.updateMilestone(milestone);
}