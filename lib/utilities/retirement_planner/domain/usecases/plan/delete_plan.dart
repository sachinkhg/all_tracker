// ./lib/utilities/retirement_planner/domain/usecases/plan/delete_plan.dart
/*
  purpose:
    - Encapsulates the "Delete Retirement Plan" use case in the domain layer.
*/

import '../../repositories/retirement_plan_repository.dart';

/// Use case class responsible for deleting a RetirementPlan.
class DeletePlan {
  final RetirementPlanRepository repository;

  DeletePlan(this.repository);

  Future<bool> call(String id) async {
    return await repository.deletePlan(id);
  }
}

