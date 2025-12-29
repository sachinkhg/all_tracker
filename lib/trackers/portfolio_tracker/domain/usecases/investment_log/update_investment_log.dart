// lib/trackers/portfolio_tracker/domain/usecases/investment_log/update_investment_log.dart
// Use case for updating an investment log

import '../../entities/investment_log.dart';
import '../../repositories/investment_log_repository.dart';

/// Use case class responsible for updating an existing [InvestmentLog].
class UpdateInvestmentLog {
  final InvestmentLogRepository repository;
  UpdateInvestmentLog(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(InvestmentLog log) async => repository.updateInvestmentLog(log);
}

