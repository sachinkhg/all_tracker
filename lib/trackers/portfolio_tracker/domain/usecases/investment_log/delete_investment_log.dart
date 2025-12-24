// lib/trackers/portfolio_tracker/domain/usecases/investment_log/delete_investment_log.dart
// Use case for deleting an investment log

import '../../repositories/investment_log_repository.dart';

/// Use case class responsible for deleting an [InvestmentLog].
class DeleteInvestmentLog {
  final InvestmentLogRepository repository;
  DeleteInvestmentLog(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteInvestmentLog(id);
}

