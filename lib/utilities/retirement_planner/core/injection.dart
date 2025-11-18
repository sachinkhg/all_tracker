// lib/utilities/retirement_planner/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/retirement_plan_local_data_source.dart';
import '../data/repositories/retirement_plan_repository_impl.dart';
import '../data/models/retirement_plan_model.dart';
import '../domain/usecases/plan/create_plan.dart';
import '../domain/usecases/plan/get_all_plans.dart';
import '../domain/usecases/plan/get_plan_by_id.dart';
import '../domain/usecases/plan/update_plan.dart';
import '../domain/usecases/plan/delete_plan.dart';
import '../domain/usecases/plan/calculate_retirement_plan.dart';

import '../presentation/bloc/retirement_plan_cubit.dart';

import 'constants.dart';

/// Factory that constructs a fully-wired RetirementPlanCubit.
RetirementPlanCubit createRetirementPlanCubit() {
  final Box<RetirementPlanModel> box =
      Hive.box<RetirementPlanModel>(retirementPlanBoxName);

  // Data layer
  final local = RetirementPlanLocalDataSourceImpl(box);

  // Repository layer
  final repo = RetirementPlanRepositoryImpl(local);

  // Use-cases
  final getAllPlans = GetAllPlans(repo);
  final getPlanById = GetPlanById(repo);
  final createPlan = CreatePlan(repo);
  final updatePlan = UpdatePlan(repo);
  final deletePlan = DeletePlan(repo);
  final calculateRetirementPlan = CalculateRetirementPlan();

  // Presentation
  return RetirementPlanCubit(
    getAllPlans: getAllPlans,
    getPlanById: getPlanById,
    createPlan: createPlan,
    updatePlan: updatePlan,
    deletePlan: deletePlan,
    calculateRetirementPlan: calculateRetirementPlan,
  );
}

