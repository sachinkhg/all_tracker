/*
 * File: retirement_plan_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (RetirementPlan entity)
 *    with the data layer (RetirementPlanModel / Hive-backed datasource).
 */

import '../../domain/entities/retirement_plan.dart';
import '../../domain/repositories/retirement_plan_repository.dart';
import '../datasources/retirement_plan_local_data_source.dart';
import '../models/retirement_plan_model.dart';

/// Concrete implementation of RetirementPlanRepository.
class RetirementPlanRepositoryImpl implements RetirementPlanRepository {
  final RetirementPlanLocalDataSource local;

  RetirementPlanRepositoryImpl(this.local);

  @override
  Future<RetirementPlan> createPlan(RetirementPlan plan) async {
    final model = RetirementPlanModel.fromEntity(plan);
    await local.createPlan(model);
    return plan;
  }

  @override
  Future<bool> deletePlan(String id) async {
    await local.deletePlan(id);
    return true;
  }

  @override
  Future<List<RetirementPlan>> getAllPlans() async {
    final models = await local.getAllPlans();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<RetirementPlan?> getPlanById(String id) async {
    final model = await local.getPlanById(id);
    return model?.toEntity();
  }

  @override
  Future<RetirementPlan> updatePlan(RetirementPlan plan) async {
    final model = RetirementPlanModel.fromEntity(plan);
    await local.updatePlan(model);
    return plan;
  }
}

