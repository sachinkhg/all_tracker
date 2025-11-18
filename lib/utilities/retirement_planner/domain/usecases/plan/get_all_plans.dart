// ./lib/utilities/retirement_planner/domain/usecases/plan/get_all_plans.dart
/*
  purpose:
    - Encapsulates the "Get All Retirement Plans" use case in the domain layer.
*/

import '../../entities/retirement_plan.dart';
import '../../repositories/retirement_plan_repository.dart';

/// Use case class responsible for retrieving all RetirementPlans.
class GetAllPlans {
  final RetirementPlanRepository repository;

  GetAllPlans(this.repository);

  Future<List<RetirementPlan>> call() async {
    return await repository.getAllPlans();
  }
}

