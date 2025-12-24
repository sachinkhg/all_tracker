// lib/trackers/portfolio_tracker/domain/usecases/redemption_log/update_redemption_log.dart
// Use case for updating a redemption log

import '../../entities/redemption_log.dart';
import '../../repositories/redemption_log_repository.dart';

/// Use case class responsible for updating an existing [RedemptionLog].
class UpdateRedemptionLog {
  final RedemptionLogRepository repository;
  UpdateRedemptionLog(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(RedemptionLog log) async => repository.updateRedemptionLog(log);
}

