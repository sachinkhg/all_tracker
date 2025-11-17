// ./lib/utilities/investment_planner/domain/usecases/plan/update_plan.dart
/*
  purpose:
    - Encapsulates the "Update Investment Plan" use case in the domain layer.
*/

import '../../entities/investment_plan.dart';
import '../../repositories/investment_plan_repository.dart';

/// Use case class responsible for updating an existing InvestmentPlan.
class UpdatePlan {
  final InvestmentPlanRepository repository;

  UpdatePlan(this.repository);

  Future<InvestmentPlan> call(InvestmentPlan plan) async {
    return await repository.updatePlan(plan);
  }
}

