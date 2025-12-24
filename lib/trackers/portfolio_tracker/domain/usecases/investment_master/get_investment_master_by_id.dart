// lib/trackers/portfolio_tracker/domain/usecases/investment_master/get_investment_master_by_id.dart
// Use case for getting an investment master by id

import '../../entities/investment_master.dart';
import '../../repositories/investment_master_repository.dart';

/// Use case class responsible for retrieving an [InvestmentMaster] by its id.
class GetInvestmentMasterById {
  final InvestmentMasterRepository repository;
  GetInvestmentMasterById(this.repository);

  /// Executes the get by id operation asynchronously.
  Future<InvestmentMaster?> call(String id) async => repository.getInvestmentMasterById(id);
}

