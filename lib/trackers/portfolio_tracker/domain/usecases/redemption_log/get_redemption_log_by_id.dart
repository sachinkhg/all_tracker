// lib/trackers/portfolio_tracker/domain/usecases/redemption_log/get_redemption_log_by_id.dart
// Use case for getting a redemption log by id

import '../../entities/redemption_log.dart';
import '../../repositories/redemption_log_repository.dart';

/// Use case class responsible for retrieving a [RedemptionLog] by its id.
class GetRedemptionLogById {
  final RedemptionLogRepository repository;
  GetRedemptionLogById(this.repository);

  /// Executes the get by id operation asynchronously.
  Future<RedemptionLog?> call(String id) async => repository.getRedemptionLogById(id);
}

