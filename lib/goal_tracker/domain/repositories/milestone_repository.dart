import '../entities/milestone.dart';

abstract class MilestoneRepository {
  Future<List<Milestone>> getMilestones();
  Future<Milestone?> getMilestoneById(String id);
  Future<void> addMilestone(Milestone milestone);
  Future<void> updateMilestone(Milestone milestone);
  Future<void> deleteMilestone(String id);
  Future<void> clearAll();
}
