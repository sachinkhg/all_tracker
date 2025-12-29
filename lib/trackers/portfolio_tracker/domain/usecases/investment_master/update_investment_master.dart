// lib/trackers/portfolio_tracker/domain/usecases/investment_master/update_investment_master.dart
// Use case for updating an investment master

import '../../entities/investment_master.dart';
import '../../repositories/investment_master_repository.dart';

/// Use case class responsible for updating an existing [InvestmentMaster].
class UpdateInvestmentMaster {
  final InvestmentMasterRepository repository;
  UpdateInvestmentMaster(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(InvestmentMaster master) async => repository.updateInvestmentMaster(master);
}

