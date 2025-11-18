// ./lib/utilities/retirement_planner/domain/usecases/plan/create_plan.dart
/*
  purpose:
    - Encapsulates the "Create Retirement Plan" use case in the domain layer.
*/

import '../../entities/retirement_plan.dart';
import '../../repositories/retirement_plan_repository.dart';

/// Use case class responsible for creating a new RetirementPlan.
class CreatePlan {
  final RetirementPlanRepository repository;

  CreatePlan(this.repository);

  Future<RetirementPlan> call(RetirementPlan plan) async {
    return await repository.createPlan(plan);
  }
}

