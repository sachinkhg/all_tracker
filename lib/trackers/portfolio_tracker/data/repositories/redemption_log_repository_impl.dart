// lib/trackers/portfolio_tracker/data/repositories/redemption_log_repository_impl.dart
// Concrete implementation of RedemptionLogRepository

import '../../domain/entities/redemption_log.dart';
import '../../domain/repositories/redemption_log_repository.dart';
import '../datasources/redemption_log_local_data_source.dart';
import '../models/redemption_log_model.dart';

/// Concrete implementation of [RedemptionLogRepository] using Hive for persistence.
class RedemptionLogRepositoryImpl implements RedemptionLogRepository {
  final RedemptionLogLocalDataSource dataSource;

  RedemptionLogRepositoryImpl(this.dataSource);

  @override
  Future<List<RedemptionLog>> getAllRedemptionLogs() async {
    final models = await dataSource.getAllRedemptionLogs();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RedemptionLog?> getRedemptionLogById(String id) async {
    final model = await dataSource.getRedemptionLogById(id);
    return model?.toEntity();
  }

  @override
  Future<List<RedemptionLog>> getRedemptionLogsByInvestmentId(String investmentId) async {
    final models = await dataSource.getRedemptionLogsByInvestmentId(investmentId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> createRedemptionLog(RedemptionLog log) async {
    final model = RedemptionLogModel.fromEntity(log);
    await dataSource.createRedemptionLog(model);
  }

  @override
  Future<void> updateRedemptionLog(RedemptionLog log) async {
    final model = RedemptionLogModel.fromEntity(log);
    await dataSource.updateRedemptionLog(model);
  }

  @override
  Future<void> deleteRedemptionLog(String id) async {
    await dataSource.deleteRedemptionLog(id);
  }
}

