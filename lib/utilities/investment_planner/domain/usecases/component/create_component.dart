// ./lib/utilities/investment_planner/domain/usecases/component/create_component.dart
/*
  purpose:
    - Encapsulates the "Create Investment Component" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new InvestmentComponent
      via the InvestmentComponentRepository abstraction.
*/

import '../../entities/investment_component.dart';
import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for creating a new InvestmentComponent.
class CreateComponent {
  final InvestmentComponentRepository repository;

  CreateComponent(this.repository);

  Future<InvestmentComponent> call(InvestmentComponent component) async {
    return await repository.createComponent(component);
  }
}

