// ./lib/utilities/investment_planner/domain/usecases/component/get_all_components.dart
/*
  purpose:
    - Encapsulates the "Get All Investment Components" domain use case.
*/

import '../../entities/investment_component.dart';
import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for fetching all InvestmentComponent entities.
class GetAllComponents {
  final InvestmentComponentRepository repository;

  GetAllComponents(this.repository);

  Future<List<InvestmentComponent>> call() async {
    return await repository.getAllComponents();
  }
}

