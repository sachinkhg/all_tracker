// ./lib/utilities/investment_planner/domain/usecases/plan/delete_plan.dart
/*
  purpose:
    - Encapsulates the "Delete Investment Plan" use case in the domain layer.
*/

import '../../repositories/investment_plan_repository.dart';

/// Use case class responsible for deleting an InvestmentPlan.
class DeletePlan {
  final InvestmentPlanRepository repository;

  DeletePlan(this.repository);

  Future<bool> call(String id) async {
    return await repository.deletePlan(id);
  }
}

