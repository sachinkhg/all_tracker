// ./lib/utilities/investment_planner/domain/usecases/component/update_component.dart
/*
  purpose:
    - Encapsulates the "Update Investment Component" use case in the domain layer.
*/

import '../../entities/investment_component.dart';
import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for updating an existing InvestmentComponent.
class UpdateComponent {
  final InvestmentComponentRepository repository;

  UpdateComponent(this.repository);

  Future<InvestmentComponent> call(InvestmentComponent component) async {
    return await repository.updateComponent(component);
  }
}

