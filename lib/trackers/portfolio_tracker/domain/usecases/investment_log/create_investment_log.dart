// lib/trackers/portfolio_tracker/domain/usecases/investment_log/create_investment_log.dart
// Use case for creating an investment log

import '../../entities/investment_log.dart';
import '../../repositories/investment_log_repository.dart';

/// Use case class responsible for creating a new [InvestmentLog].
class CreateInvestmentLog {
  final InvestmentLogRepository repository;
  CreateInvestmentLog(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(InvestmentLog log) async => repository.createInvestmentLog(log);
}

