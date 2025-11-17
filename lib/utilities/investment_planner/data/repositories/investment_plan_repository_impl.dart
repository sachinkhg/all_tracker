/*
 * File: investment_plan_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (InvestmentPlan entity)
 *    with the data layer (InvestmentPlanModel / Hive-backed datasource).
 */

import '../../domain/entities/investment_plan.dart';
import '../../domain/repositories/investment_plan_repository.dart';
import '../datasources/investment_plan_local_data_source.dart';
import '../models/investment_plan_model.dart';

/// Concrete implementation of InvestmentPlanRepository.
class InvestmentPlanRepositoryImpl implements InvestmentPlanRepository {
  final InvestmentPlanLocalDataSource local;

  InvestmentPlanRepositoryImpl(this.local);

  @override
  Future<InvestmentPlan> createPlan(InvestmentPlan plan) async {
    final model = InvestmentPlanModel.fromEntity(plan);
    await local.createPlan(model);
    return plan;
  }

  @override
  Future<bool> deletePlan(String id) async {
    await local.deletePlan(id);
    return true;
  }

  @override
  Future<List<InvestmentPlan>> getAllPlans() async {
    final models = await local.getAllPlans();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<InvestmentPlan?> getPlanById(String id) async {
    final model = await local.getPlanById(id);
    return model?.toEntity();
  }

  @override
  Future<InvestmentPlan> updatePlan(InvestmentPlan plan) async {
    final model = InvestmentPlanModel.fromEntity(plan);
    await local.updatePlan(model);
    return plan;
  }
}

