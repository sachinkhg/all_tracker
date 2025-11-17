/*
  purpose:
    - Retrieves all milestones associated with a specific [Goal].
    - Supports goal-detail screens or progress tracking UIs by returning
      all linked milestones.

  usage:
    - Invoked by higher-level logic when loading a goal’s milestone list.
*/

import '../../entities/milestone.dart';
import '../../repositories/milestone_repository.dart';

/// Use case for retrieving milestones belonging to a specific goal.
class GetMilestonesByGoalId {
  final MilestoneRepository repository;
  GetMilestonesByGoalId(this.repository);

  /// Executes the retrieval for the given [goalId].
  Future<List<Milestone>> call(String goalId) async =>
      repository.getMilestonesByGoalId(goalId);
}
