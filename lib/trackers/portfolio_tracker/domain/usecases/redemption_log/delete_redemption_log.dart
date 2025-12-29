// lib/trackers/portfolio_tracker/domain/usecases/redemption_log/delete_redemption_log.dart
// Use case for deleting a redemption log

import '../../repositories/redemption_log_repository.dart';

/// Use case class responsible for deleting a [RedemptionLog].
class DeleteRedemptionLog {
  final RedemptionLogRepository repository;
  DeleteRedemptionLog(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteRedemptionLog(id);
}

