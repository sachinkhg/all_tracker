/*
 * File: ./lib/utilities/investment_planner/domain/repositories/investment_component_repository.dart
 *
 * Purpose:
 *   Abstract repository interface for Investment Component operations.
 *   Defines the contract for persistence operations without implementation details.
 *
 * Notes for implementers:
 *   - This interface should remain implementation-agnostic.
 *   - Concrete implementations live in the data layer.
 */

import '../entities/investment_component.dart';

/// Abstract repository interface for Investment Component operations.
abstract class InvestmentComponentRepository {
  /// Creates a new investment component.
  ///
  /// Returns the created component or throws an exception on failure.
  Future<InvestmentComponent> createComponent(InvestmentComponent component);

  /// Retrieves all investment components.
  ///
  /// Returns a list of all components, ordered by priority.
  Future<List<InvestmentComponent>> getAllComponents();

  /// Retrieves an investment component by ID.
  ///
  /// Returns the component if found, or null if not found.
  Future<InvestmentComponent?> getComponentById(String id);

  /// Updates an existing investment component.
  ///
  /// Returns the updated component or throws an exception on failure.
  Future<InvestmentComponent> updateComponent(InvestmentComponent component);

  /// Deletes an investment component by ID.
  ///
  /// Returns true if deleted, false if not found.
  Future<bool> deleteComponent(String id);
}

