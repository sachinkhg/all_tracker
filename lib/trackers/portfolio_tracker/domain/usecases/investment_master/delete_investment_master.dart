// lib/trackers/portfolio_tracker/domain/usecases/investment_master/delete_investment_master.dart
// Use case for deleting an investment master

import '../../repositories/investment_master_repository.dart';

/// Use case class responsible for deleting an [InvestmentMaster].
class DeleteInvestmentMaster {
  final InvestmentMasterRepository repository;
  DeleteInvestmentMaster(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteInvestmentMaster(id);
}

