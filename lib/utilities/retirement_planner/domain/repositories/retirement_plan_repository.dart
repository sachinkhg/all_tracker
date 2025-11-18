/*
 * File: ./lib/utilities/retirement_planner/domain/repositories/retirement_plan_repository.dart
 *
 * Purpose:
 *   Abstract repository interface for Retirement Plan operations.
 *   Defines the contract for persistence operations without implementation details.
 */

import '../entities/retirement_plan.dart';

/// Abstract repository interface for Retirement Plan operations.
abstract class RetirementPlanRepository {
  /// Creates a new retirement plan.
  Future<RetirementPlan> createPlan(RetirementPlan plan);

  /// Retrieves all retirement plans.
  Future<List<RetirementPlan>> getAllPlans();

  /// Retrieves a retirement plan by ID.
  Future<RetirementPlan?> getPlanById(String id);

  /// Updates an existing retirement plan.
  Future<RetirementPlan> updatePlan(RetirementPlan plan);

  /// Deletes a retirement plan by ID.
  Future<bool> deletePlan(String id);
}

