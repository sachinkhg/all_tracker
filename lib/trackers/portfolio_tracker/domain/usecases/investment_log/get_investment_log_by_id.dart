// lib/trackers/portfolio_tracker/domain/usecases/investment_log/get_investment_log_by_id.dart
// Use case for getting an investment log by id

import '../../entities/investment_log.dart';
import '../../repositories/investment_log_repository.dart';

/// Use case class responsible for retrieving an [InvestmentLog] by its id.
class GetInvestmentLogById {
  final InvestmentLogRepository repository;
  GetInvestmentLogById(this.repository);

  /// Executes the get by id operation asynchronously.
  Future<InvestmentLog?> call(String id) async => repository.getInvestmentLogById(id);
}

