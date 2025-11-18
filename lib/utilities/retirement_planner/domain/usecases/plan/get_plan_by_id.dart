// ./lib/utilities/retirement_planner/domain/usecases/plan/get_plan_by_id.dart
/*
  purpose:
    - Encapsulates the "Get Retirement Plan by ID" use case in the domain layer.
*/

import '../../entities/retirement_plan.dart';
import '../../repositories/retirement_plan_repository.dart';

/// Use case class responsible for retrieving a RetirementPlan by ID.
class GetPlanById {
  final RetirementPlanRepository repository;

  GetPlanById(this.repository);

  Future<RetirementPlan?> call(String id) async {
    return await repository.getPlanById(id);
  }
}

