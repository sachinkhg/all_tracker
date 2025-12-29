// lib/trackers/portfolio_tracker/domain/usecases/redemption_log/get_redemption_logs_by_master.dart
// Use case for getting redemption logs by investment master id

import '../../entities/redemption_log.dart';
import '../../repositories/redemption_log_repository.dart';

/// Use case class responsible for retrieving all [RedemptionLog] entities for a specific investment master.
class GetRedemptionLogsByMaster {
  final RedemptionLogRepository repository;
  GetRedemptionLogsByMaster(this.repository);

  /// Executes the get by investment id operation asynchronously.
  Future<List<RedemptionLog>> call(String investmentId) async =>
      repository.getRedemptionLogsByInvestmentId(investmentId);
}

