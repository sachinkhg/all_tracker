import '../../../domain/entities/milestone.dart';

abstract class MilestoneEvent {}

class LoadMilestones extends MilestoneEvent {}

class GetMilestoneDetails extends MilestoneEvent {
  final String id;
  GetMilestoneDetails(this.id);
}

class AddMilestoneEvent extends MilestoneEvent {
  final Milestone milestone;
  AddMilestoneEvent(this.milestone);
}

class UpdateMilestoneEvent extends MilestoneEvent {
  final Milestone milestone;
  UpdateMilestoneEvent(this.milestone);
}

class DeleteMilestoneEvent extends MilestoneEvent {
  final String id;
  DeleteMilestoneEvent(this.id);
}

class ClearAllMilestonesEvent extends MilestoneEvent {}
