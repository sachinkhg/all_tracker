/*
 * File: investment_plan_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Investment Plan objects.
 */

import 'package:hive/hive.dart';
import '../models/investment_plan_model.dart';

/// Abstract data source for local (Hive) investment plan storage.
abstract class InvestmentPlanLocalDataSource {
  Future<List<InvestmentPlanModel>> getAllPlans();
  Future<InvestmentPlanModel?> getPlanById(String id);
  Future<void> createPlan(InvestmentPlanModel plan);
  Future<void> updatePlan(InvestmentPlanModel plan);
  Future<void> deletePlan(String id);
}

/// Hive implementation of InvestmentPlanLocalDataSource.
class InvestmentPlanLocalDataSourceImpl
    implements InvestmentPlanLocalDataSource {
  final Box<InvestmentPlanModel> box;

  InvestmentPlanLocalDataSourceImpl(this.box);

  @override
  Future<void> createPlan(InvestmentPlanModel plan) async {
    await box.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await box.delete(id);
  }

  @override
  Future<InvestmentPlanModel?> getPlanById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<InvestmentPlanModel>> getAllPlans() async {
    return box.values.toList();
  }

  @override
  Future<void> updatePlan(InvestmentPlanModel plan) async {
    await box.put(plan.id, plan);
  }
}

