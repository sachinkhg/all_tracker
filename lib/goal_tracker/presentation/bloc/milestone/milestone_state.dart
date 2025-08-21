import '../../../domain/entities/milestone.dart';

abstract class MilestoneState {}

class MilestoneInitial extends MilestoneState {}

class MilestoneLoading extends MilestoneState {}

class MilestoneLoaded extends MilestoneState {
  final List<Milestone> milestones;
  MilestoneLoaded(this.milestones);
}

class MilestoneDetailsLoaded extends MilestoneState {
  final Milestone? milestone; // null if not found
  MilestoneDetailsLoaded(this.milestone);
}

class MilestoneError extends MilestoneState {
  final String message;
  MilestoneError(this.message);
}
