/*
 * File: retirement_plan_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Retirement Plan objects.
 */

import 'package:hive/hive.dart';
import '../models/retirement_plan_model.dart';

/// Abstract data source for local (Hive) retirement plan storage.
abstract class RetirementPlanLocalDataSource {
  Future<List<RetirementPlanModel>> getAllPlans();
  Future<RetirementPlanModel?> getPlanById(String id);
  Future<void> createPlan(RetirementPlanModel plan);
  Future<void> updatePlan(RetirementPlanModel plan);
  Future<void> deletePlan(String id);
}

/// Hive implementation of RetirementPlanLocalDataSource.
class RetirementPlanLocalDataSourceImpl
    implements RetirementPlanLocalDataSource {
  final Box<RetirementPlanModel> box;

  RetirementPlanLocalDataSourceImpl(this.box);

  @override
  Future<void> createPlan(RetirementPlanModel plan) async {
    await box.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await box.delete(id);
  }

  @override
  Future<RetirementPlanModel?> getPlanById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<RetirementPlanModel>> getAllPlans() async {
    return box.values.toList();
  }

  @override
  Future<void> updatePlan(RetirementPlanModel plan) async {
    await box.put(plan.id, plan);
  }
}

