// ./lib/utilities/investment_planner/domain/usecases/plan/create_plan.dart
/*
  purpose:
    - Encapsulates the "Create Investment Plan" use case in the domain layer.
*/

import '../../entities/investment_plan.dart';
import '../../repositories/investment_plan_repository.dart';

/// Use case class responsible for creating a new InvestmentPlan.
class CreatePlan {
  final InvestmentPlanRepository repository;

  CreatePlan(this.repository);

  Future<InvestmentPlan> call(InvestmentPlan plan) async {
    return await repository.createPlan(plan);
  }
}

