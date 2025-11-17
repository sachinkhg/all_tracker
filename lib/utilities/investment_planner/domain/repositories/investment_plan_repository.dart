/*
 * File: ./lib/utilities/investment_planner/domain/repositories/investment_plan_repository.dart
 *
 * Purpose:
 *   Abstract repository interface for Investment Plan operations.
 *   Defines the contract for persistence operations without implementation details.
 */

import '../entities/investment_plan.dart';

/// Abstract repository interface for Investment Plan operations.
abstract class InvestmentPlanRepository {
  /// Creates a new investment plan.
  Future<InvestmentPlan> createPlan(InvestmentPlan plan);

  /// Retrieves all investment plans.
  Future<List<InvestmentPlan>> getAllPlans();

  /// Retrieves an investment plan by ID.
  Future<InvestmentPlan?> getPlanById(String id);

  /// Updates an existing investment plan.
  Future<InvestmentPlan> updatePlan(InvestmentPlan plan);

  /// Deletes an investment plan by ID.
  Future<bool> deletePlan(String id);
}

