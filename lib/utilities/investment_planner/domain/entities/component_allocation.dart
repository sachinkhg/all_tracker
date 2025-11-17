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

  /// Allocated amount for this component.
  final double allocatedAmount;

  /// Domain constructor.
  const ComponentAllocation({
    required this.componentId,
    required this.allocatedAmount,
  });

  /// Creates a copy of this ComponentAllocation with the given fields replaced.
  ComponentAllocation copyWith({
    String? componentId,
    double? allocatedAmount,
  }) {
    return ComponentAllocation(
      componentId: componentId ?? this.componentId,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
    );
  }

  @override
  List<Object?> get props => [componentId, allocatedAmount];
}

