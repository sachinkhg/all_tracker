// ./lib/utilities/investment_planner/domain/usecases/component/get_component_by_id.dart
/*
  purpose:
    - Encapsulates the "Get Investment Component By ID" domain use case.
*/

import '../../entities/investment_component.dart';
import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for fetching a single InvestmentComponent by ID.
class GetComponentById {
  final InvestmentComponentRepository repository;

  GetComponentById(this.repository);

  Future<InvestmentComponent?> call(String id) async {
    return await repository.getComponentById(id);
  }
}

