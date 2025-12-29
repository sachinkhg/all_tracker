// lib/trackers/portfolio_tracker/data/datasources/redemption_log_local_data_source.dart
// Hive-backed local data source for RedemptionLog objects

import 'package:hive/hive.dart';
import '../models/redemption_log_model.dart';

/// Abstract data source for local (Hive) redemption log storage.
///
/// Implementations should be simple adapters that read/write RedemptionLogModel instances.
/// Conversions between domain entity and DTO should be implemented in RedemptionLogModel.
abstract class RedemptionLogLocalDataSource {
  /// Returns all redemption logs stored in the local box.
  Future<List<RedemptionLogModel>> getAllRedemptionLogs();

  /// Returns a single RedemptionLogModel by its string id key, or null if not found.
  Future<RedemptionLogModel?> getRedemptionLogById(String id);

  /// Returns all redemption logs for a specific investment master.
  Future<List<RedemptionLogModel>> getRedemptionLogsByInvestmentId(String investmentId);

  /// Persists a new RedemptionLogModel. The implementation is expected to use log.id as key.
  Future<void> createRedemptionLog(RedemptionLogModel log);

  /// Updates an existing RedemptionLogModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateRedemptionLog(RedemptionLogModel log);

  /// Deletes a redemption log by its id key.
  Future<void> deleteRedemptionLog(String id);
}

/// Hive implementation of [RedemptionLogLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// RedemptionLogModel persistence. It uses `log.id` (String) as the Hive key.
class RedemptionLogLocalDataSourceImpl implements RedemptionLogLocalDataSource {
  /// Hive box that stores [RedemptionLogModel] entries.
  final Box<RedemptionLogModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the RedemptionLogModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  RedemptionLogLocalDataSourceImpl(this.box);

  @override
  Future<void> createRedemptionLog(RedemptionLogModel log) async {
    await box.put(log.id, log);
  }

  @override
  Future<void> deleteRedemptionLog(String id) async {
    await box.delete(id);
  }

  @override
  Future<RedemptionLogModel?> getRedemptionLogById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<RedemptionLogModel>> getAllRedemptionLogs() async {
    return box.values.toList();
  }

  @override
  Future<List<RedemptionLogModel>> getRedemptionLogsByInvestmentId(String investmentId) async {
    final allLogs = box.values.toList();
    return allLogs.where((log) => log.investmentId == investmentId).toList();
  }

  @override
  Future<void> updateRedemptionLog(RedemptionLogModel log) async {
    await box.put(log.id, log);
  }
}

