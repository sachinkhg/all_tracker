import 'package:hive/hive.dart';
import '../models/milestone_model.dart';

class MilestoneLocalDataSource {
  final Box<MilestoneModel> milestoneBox;

  MilestoneLocalDataSource(this.milestoneBox);

  // Retrieve all Milestones from the box
  List<MilestoneModel> getMilestones() {
    return milestoneBox.values.toList();
  }

  // Get a single Milestone by id
  MilestoneModel? getMilestoneById(String id) {
    return milestoneBox.get(id);
  }

    // Get a single Milestone by id
  MilestoneModel? getMilestoneByName(String name) {
    return milestoneBox.get(name);
  }

  // Add a new Milestone
  Future<void> addMilestone(MilestoneModel milestone) async {
    await milestoneBox.put(milestone.id, milestone);
  }

  // Update an existing Milestone
  Future<void> updateMilestone(MilestoneModel milestone) async {
    await milestoneBox.put(milestone.id, milestone);
  }

  // Delete a Milestone by id
  Future<void> deleteMilestone(String id) async {
    await milestoneBox.delete(id);
  }

  // Additional utility: Clear all milestones (optional)
  Future<void> clearAll() async {
    await milestoneBox.clear();
  }
}
