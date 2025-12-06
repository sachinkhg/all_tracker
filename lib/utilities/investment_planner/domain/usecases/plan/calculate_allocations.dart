// ./lib/utilities/investment_planner/domain/usecases/plan/calculate_allocations.dart
/*
  purpose:
    - Encapsulates the "Calculate Allocations" use case in the domain layer.
    - Implements the allocation algorithm based on priority, percentage, and limits.
*/

import '../../entities/component_allocation.dart';
import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for calculating component allocations.
///
/// Allocation Algorithm:
/// 1. Calculate available amount = sum(income) - sum(expenses)
/// 2. Sort components by priority (ascending)
/// 3. For each component (in priority order):
///    - Calculate target allocation = available * (percentage / 100)
///    - Apply min limit if specified: target = max(target, minLimit)
///    - Apply max limit if specified: target = min(target, maxLimit)
///    - If available funds < target, allocate what's available
///    - Subtract allocated amount from available funds
/// 4. Return allocations and remaining unallocated amount
class CalculateAllocations {
  final InvestmentComponentRepository componentRepository;

  CalculateAllocations(this.componentRepository);

  /// Calculates allocations for the given available amount.
  ///
  /// Returns a map with:
  /// - 'allocations': List of ComponentAllocation
  /// - 'remainingUnallocated': double
  Future<Map<String, dynamic>> call(double availableAmount) async {
    // Get all components
    final components = await componentRepository.getAllComponents();

    // Sort by priority (ascending - lower number = higher priority)
    components.sort((a, b) => a.priority.compareTo(b.priority));

    final List<ComponentAllocation> allocations = [];
    double remaining = availableAmount;
    // Store initial available amount for percentage calculations
    final double initialAvailableAmount = availableAmount;

    // Allocate funds to each component in priority order
    for (final component in components) {
      // Calculate target allocation based on percentage of INITIAL available amount
      double target = initialAvailableAmount * (component.percentage / 100);

      // Apply min limit if specified
      if (component.minLimit != null) {
        target = target > component.minLimit! ? target : component.minLimit!;
      }

      // Apply max limit if specified
      if (component.maxLimit != null) {
        target = target < component.maxLimit! ? target : component.maxLimit!;
      }

      // Allocate what's available (cannot exceed remaining funds)
      double allocatedAmount = target > remaining ? remaining : target;
      
      // Round to nearest multiple if specified
      if (component.multipleOf != null && component.multipleOf! > 0) {
        allocatedAmount = (allocatedAmount / component.multipleOf!).round() * component.multipleOf!;
        // Ensure rounded amount doesn't exceed remaining funds
        if (allocatedAmount > remaining) {
          allocatedAmount = (remaining / component.multipleOf!).floor() * component.multipleOf!;
        }
      }
      
      if (allocatedAmount > 0) {
        allocations.add(ComponentAllocation(
          componentId: component.id,
          allocatedAmount: allocatedAmount,
        ));
        remaining -= allocatedAmount;
      }

      // If no funds remaining, break early
      if (remaining <= 0) {
        break;
      }
    }

    return {
      'allocations': allocations,
      'remainingUnallocated': remaining,
    };
  }
}

