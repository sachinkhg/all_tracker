import '../entities/milestone.dart';
import '../repositories/milestone_repository.dart';

// ----------------------
// Get all Milestone
// ----------------------
class GetMilestones {
  final MilestoneRepository repository;
  GetMilestones(this.repository);

  Future<List<Milestone>> call() {
    return repository.getMilestones();
  }
}

// ----------------------
// Get Milestone by ID
// ----------------------
class GetMilestoneById {
  final MilestoneRepository repository;
  GetMilestoneById(this.repository);

  Future<Milestone?> call(String id) {
    return repository.getMilestoneById(id);
  }
}

// ----------------------
// Add Milestone
// ----------------------
class AddMilestone {
  final MilestoneRepository repository;
  AddMilestone(this.repository);

  Future<void> call(Milestone milestone) {
    return repository.addMilestone(milestone);
  }
}

// ----------------------
// Update Milestone
// ----------------------
class UpdateMilestone {
  final MilestoneRepository repository;
  UpdateMilestone(this.repository);

  Future<void> call(Milestone milestone) {
    return repository.updateMilestone(milestone);
  }
}

// ----------------------
// Delete Milestone
// ----------------------
class DeleteMilestone {
  final MilestoneRepository repository;
  DeleteMilestone(this.repository);

  Future<void> call(String id) {
    return repository.deleteMilestone(id);
  }
}

// ----------------------
// Clear All Milestone
// ----------------------
class ClearAllMilestones {
  final MilestoneRepository repository;
  ClearAllMilestones(this.repository);

  Future<void> call() {
    return repository.clearAll();
  }
}

class GetMilestonesForGoal {
  final MilestoneRepository repository;
  GetMilestonesForGoal(this.repository);

  Future<List<Milestone>> call(String associatedGoalID) {
    return repository.getMilestonesForGoal(associatedGoalID);
  }
}
