// ./lib/utilities/retirement_planner/domain/usecases/plan/update_plan.dart
/*
  purpose:
    - Encapsulates the "Update Retirement Plan" use case in the domain layer.
*/

import '../../entities/retirement_plan.dart';
import '../../repositories/retirement_plan_repository.dart';

/// Use case class responsible for updating an existing RetirementPlan.
class UpdatePlan {
  final RetirementPlanRepository repository;

  UpdatePlan(this.repository);

  Future<RetirementPlan> call(RetirementPlan plan) async {
    return await repository.updatePlan(plan);
  }
}

