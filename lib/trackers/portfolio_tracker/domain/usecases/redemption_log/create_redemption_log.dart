// lib/trackers/portfolio_tracker/domain/usecases/redemption_log/create_redemption_log.dart
// Use case for creating a redemption log

import '../../entities/redemption_log.dart';
import '../../repositories/redemption_log_repository.dart';

/// Use case class responsible for creating a new [RedemptionLog].
class CreateRedemptionLog {
  final RedemptionLogRepository repository;
  CreateRedemptionLog(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(RedemptionLog log) async => repository.createRedemptionLog(log);
}

