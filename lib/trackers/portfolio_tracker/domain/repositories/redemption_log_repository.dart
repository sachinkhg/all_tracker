// lib/trackers/portfolio_tracker/domain/repositories/redemption_log_repository.dart
// Abstract repository interface for redemption log operations

import '../entities/redemption_log.dart';

/// Abstract repository interface for redemption log operations.
///
/// This interface defines the contract for redemption log data access operations.
/// Implementations should handle persistence, filtering, and querying logic.
abstract class RedemptionLogRepository {
  /// Retrieves all redemption logs.
  ///
  /// Returns a list of all redemption logs in the repository.
  /// Returns an empty list if no redemption logs exist.
  Future<List<RedemptionLog>> getAllRedemptionLogs();

  /// Retrieves a redemption log by its unique identifier.
  ///
  /// Returns the redemption log if found, null otherwise.
  Future<RedemptionLog?> getRedemptionLogById(String id);

  /// Retrieves all redemption logs for a specific investment master.
  ///
  /// Returns all redemption logs that belong to the specified investment master.
  Future<List<RedemptionLog>> getRedemptionLogsByInvestmentId(String investmentId);

  /// Creates a new redemption log.
  ///
  /// Throws an exception if the redemption log cannot be created.
  Future<void> createRedemptionLog(RedemptionLog log);

  /// Updates an existing redemption log.
  ///
  /// Throws an exception if the redemption log does not exist or cannot be updated.
  Future<void> updateRedemptionLog(RedemptionLog log);

  /// Deletes a redemption log by its unique identifier.
  ///
  /// Throws an exception if the redemption log does not exist or cannot be deleted.
  Future<void> deleteRedemptionLog(String id);
}

