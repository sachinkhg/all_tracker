/*
 * File: ./lib/utilities/investment_planner/domain/entities/component_allocation.dart
 *
 * Purpose:
 *   Domain representation of a Component Allocation result.
 *   Represents the calculated allocation amount for a specific investment component.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Component Allocation.
///
/// Represents the calculated allocation amount for a specific investment component
/// within an investment plan.
class ComponentAllocation extends Equatable {
  /// Reference to the investment component ID.
  final String componentId;

  /// Allocated amount for this component (planned amount).
  final double allocatedAmount;

  /// Actual investment amount for this component (nullable, defaults to null).
  final double? actualAmount;

  /// Whether this allocation has been completed.
  final bool isCompleted;

  /// Domain constructor.
  const ComponentAllocation({
    required this.componentId,
    required this.allocatedAmount,
    this.actualAmount,
    this.isCompleted = false,
  });

  /// Creates a copy of this ComponentAllocation with the given fields replaced.
  ComponentAllocation copyWith({
    String? componentId,
    double? allocatedAmount,
    double? actualAmount,
    bool? isCompleted,
  }) {
    return ComponentAllocation(
      componentId: componentId ?? this.componentId,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Calculates the variance between planned and actual investment.
  /// Returns null if actualAmount is null.
  /// Positive variance = under-invested (planned > actual)
  /// Negative variance = over-invested (actual > planned)
  double? get variance {
    if (actualAmount == null) return null;
    return allocatedAmount - actualAmount!;
  }

  @override
  List<Object?> get props => [componentId, allocatedAmount, actualAmount, isCompleted];
}

