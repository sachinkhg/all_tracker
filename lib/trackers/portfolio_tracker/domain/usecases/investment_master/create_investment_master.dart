// lib/trackers/portfolio_tracker/domain/usecases/investment_master/create_investment_master.dart
// Use case for creating an investment master

import '../../entities/investment_master.dart';
import '../../repositories/investment_master_repository.dart';

/// Use case class responsible for creating a new [InvestmentMaster].
class CreateInvestmentMaster {
  final InvestmentMasterRepository repository;
  CreateInvestmentMaster(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(InvestmentMaster master) async => repository.createInvestmentMaster(master);
}

