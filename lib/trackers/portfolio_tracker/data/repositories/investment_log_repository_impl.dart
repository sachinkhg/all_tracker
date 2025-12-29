// lib/trackers/portfolio_tracker/data/repositories/investment_log_repository_impl.dart
// Concrete implementation of InvestmentLogRepository

import '../../domain/entities/investment_log.dart';
import '../../domain/repositories/investment_log_repository.dart';
import '../datasources/investment_log_local_data_source.dart';
import '../models/investment_log_model.dart';

/// Concrete implementation of [InvestmentLogRepository] using Hive for persistence.
class InvestmentLogRepositoryImpl implements InvestmentLogRepository {
  final InvestmentLogLocalDataSource dataSource;

  InvestmentLogRepositoryImpl(this.dataSource);

  @override
  Future<List<InvestmentLog>> getAllInvestmentLogs() async {
    final models = await dataSource.getAllInvestmentLogs();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<InvestmentLog?> getInvestmentLogById(String id) async {
    final model = await dataSource.getInvestmentLogById(id);
    return model?.toEntity();
  }

  @override
  Future<List<InvestmentLog>> getInvestmentLogsByInvestmentId(String investmentId) async {
    final models = await dataSource.getInvestmentLogsByInvestmentId(investmentId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> createInvestmentLog(InvestmentLog log) async {
    final model = InvestmentLogModel.fromEntity(log);
    await dataSource.createInvestmentLog(model);
  }

  @override
  Future<void> updateInvestmentLog(InvestmentLog log) async {
    final model = InvestmentLogModel.fromEntity(log);
    await dataSource.updateInvestmentLog(model);
  }

  @override
  Future<void> deleteInvestmentLog(String id) async {
    await dataSource.deleteInvestmentLog(id);
  }
}

