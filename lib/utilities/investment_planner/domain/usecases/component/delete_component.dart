// ./lib/utilities/investment_planner/domain/usecases/component/delete_component.dart
/*
  purpose:
    - Encapsulates the "Delete Investment Component" use case in the domain layer.
*/

import '../../repositories/investment_component_repository.dart';

/// Use case class responsible for deleting an InvestmentComponent.
class DeleteComponent {
  final InvestmentComponentRepository repository;

  DeleteComponent(this.repository);

  Future<bool> call(String id) async {
    return await repository.deleteComponent(id);
  }
}

