// ./lib/utilities/investment_planner/domain/usecases/plan/get_plan_by_id.dart
/*
  purpose:
    - Encapsulates the "Get Investment Plan By ID" domain use case.
*/

import '../../entities/investment_plan.dart';
import '../../repositories/investment_plan_repository.dart';

/// Use case class responsible for fetching a single InvestmentPlan by ID.
class GetPlanById {
  final InvestmentPlanRepository repository;

  GetPlanById(this.repository);

  Future<InvestmentPlan?> call(String id) async {
    return await repository.getPlanById(id);
  }
}

