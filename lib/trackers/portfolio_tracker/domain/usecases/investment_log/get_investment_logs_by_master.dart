// lib/trackers/portfolio_tracker/domain/usecases/investment_log/get_investment_logs_by_master.dart
// Use case for getting investment logs by investment master id

import '../../entities/investment_log.dart';
import '../../repositories/investment_log_repository.dart';

/// Use case class responsible for retrieving all [InvestmentLog] entities for a specific investment master.
class GetInvestmentLogsByMaster {
  final InvestmentLogRepository repository;
  GetInvestmentLogsByMaster(this.repository);

  /// Executes the get by investment id operation asynchronously.
  Future<List<InvestmentLog>> call(String investmentId) async =>
      repository.getInvestmentLogsByInvestmentId(investmentId);
}

