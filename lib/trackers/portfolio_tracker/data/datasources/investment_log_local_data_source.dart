// lib/trackers/portfolio_tracker/data/datasources/investment_log_local_data_source.dart
// Hive-backed local data source for InvestmentLog objects

import 'package:hive/hive.dart';
import '../models/investment_log_model.dart';

/// Abstract data source for local (Hive) investment log storage.
///
/// Implementations should be simple adapters that read/write InvestmentLogModel instances.
/// Conversions between domain entity and DTO should be implemented in InvestmentLogModel.
abstract class InvestmentLogLocalDataSource {
  /// Returns all investment logs stored in the local box.
  Future<List<InvestmentLogModel>> getAllInvestmentLogs();

  /// Returns a single InvestmentLogModel by its string id key, or null if not found.
  Future<InvestmentLogModel?> getInvestmentLogById(String id);

  /// Returns all investment logs for a specific investment master.
  Future<List<InvestmentLogModel>> getInvestmentLogsByInvestmentId(String investmentId);

  /// Persists a new InvestmentLogModel. The implementation is expected to use log.id as key.
  Future<void> createInvestmentLog(InvestmentLogModel log);

  /// Updates an existing InvestmentLogModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateInvestmentLog(InvestmentLogModel log);

  /// Deletes an investment log by its id key.
  Future<void> deleteInvestmentLog(String id);
}

/// Hive implementation of [InvestmentLogLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// InvestmentLogModel persistence. It uses `log.id` (String) as the Hive key.
class InvestmentLogLocalDataSourceImpl implements InvestmentLogLocalDataSource {
  /// Hive box that stores [InvestmentLogModel] entries.
  final Box<InvestmentLogModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the InvestmentLogModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  InvestmentLogLocalDataSourceImpl(this.box);

  @override
  Future<void> createInvestmentLog(InvestmentLogModel log) async {
    await box.put(log.id, log);
  }

  @override
  Future<void> deleteInvestmentLog(String id) async {
    await box.delete(id);
  }

  @override
  Future<InvestmentLogModel?> getInvestmentLogById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<InvestmentLogModel>> getAllInvestmentLogs() async {
    return box.values.toList();
  }

  @override
  Future<List<InvestmentLogModel>> getInvestmentLogsByInvestmentId(String investmentId) async {
    final allLogs = box.values.toList();
    return allLogs.where((log) => log.investmentId == investmentId).toList();
  }

  @override
  Future<void> updateInvestmentLog(InvestmentLogModel log) async {
    await box.put(log.id, log);
  }
}

