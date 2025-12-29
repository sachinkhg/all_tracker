// lib/trackers/portfolio_tracker/domain/usecases/investment_master/get_all_investment_masters.dart
// Use case for getting all investment masters

import '../../entities/investment_master.dart';
import '../../repositories/investment_master_repository.dart';

/// Use case class responsible for retrieving all [InvestmentMaster] entities.
class GetAllInvestmentMasters {
  final InvestmentMasterRepository repository;
  GetAllInvestmentMasters(this.repository);

  /// Executes the get all operation asynchronously.
  Future<List<InvestmentMaster>> call() async => repository.getAllInvestmentMasters();
}

