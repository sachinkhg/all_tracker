// ./lib/utilities/investment_planner/domain/usecases/plan/get_all_plans.dart
/*
  purpose:
    - Encapsulates the "Get All Investment Plans" domain use case.
*/

import '../../entities/investment_plan.dart';
import '../../repositories/investment_plan_repository.dart';

/// Use case class responsible for fetching all InvestmentPlan entities.
class GetAllPlans {
  final InvestmentPlanRepository repository;

  GetAllPlans(this.repository);

  Future<List<InvestmentPlan>> call() async {
    return await repository.getAllPlans();
  }
}

