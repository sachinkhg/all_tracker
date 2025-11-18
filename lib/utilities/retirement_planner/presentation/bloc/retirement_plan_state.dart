import 'package:equatable/equatable.dart';
import '../../domain/entities/retirement_plan.dart';

/// Base state for retirement plan operations
abstract class RetirementPlanState extends Equatable {
  const RetirementPlanState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class PlansLoading extends RetirementPlanState {}

/// Loaded state
class PlansLoaded extends RetirementPlanState {
  final List<RetirementPlan> plans;

  const PlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

/// Error state
class PlansError extends RetirementPlanState {
  final String message;

  const PlansError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Plan detail loaded state
class PlanDetailLoaded extends RetirementPlanState {
  final RetirementPlan plan;

  const PlanDetailLoaded(this.plan);

  @override
  List<Object?> get props => [plan];
}

/// Plan detail error state
class PlanDetailError extends RetirementPlanState {
  final String message;

  const PlanDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

