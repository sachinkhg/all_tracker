import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/component_allocation.dart';

/// Base state for investment plan operations
abstract class InvestmentPlanState extends Equatable {
  const InvestmentPlanState();

  @override
  List<Object?> get props => [];
}

/// Loading state
class PlansLoading extends InvestmentPlanState {}

/// Loaded state
class PlansLoaded extends InvestmentPlanState {
  final List<InvestmentPlan> plans;

  const PlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

/// Error state
class PlansError extends InvestmentPlanState {
  final String message;

  const PlansError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Allocation calculation result state
class AllocationCalculated extends InvestmentPlanState {
  final List<ComponentAllocation> allocations;
  final double remainingUnallocated;

  const AllocationCalculated({
    required this.allocations,
    required this.remainingUnallocated,
  });

  @override
  List<Object?> get props => [allocations, remainingUnallocated];
}

