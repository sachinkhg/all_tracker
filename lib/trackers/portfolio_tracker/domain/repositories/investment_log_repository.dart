// lib/trackers/portfolio_tracker/domain/repositories/investment_log_repository.dart
// Abstract repository interface for investment log operations

import '../entities/investment_log.dart';

/// Abstract repository interface for investment log operations.
///
/// This interface defines the contract for investment log data access operations.
/// Implementations should handle persistence, filtering, and querying logic.
abstract class InvestmentLogRepository {
  /// Retrieves all investment logs.
  ///
  /// Returns a list of all investment logs in the repository.
  /// Returns an empty list if no investment logs exist.
  Future<List<InvestmentLog>> getAllInvestmentLogs();

  /// Retrieves an investment log by its unique identifier.
  ///
  /// Returns the investment log if found, null otherwise.
  Future<InvestmentLog?> getInvestmentLogById(String id);

  /// Retrieves all investment logs for a specific investment master.
  ///
  /// Returns all investment logs that belong to the specified investment master.
  Future<List<InvestmentLog>> getInvestmentLogsByInvestmentId(String investmentId);

  /// Creates a new investment log.
  ///
  /// Throws an exception if the investment log cannot be created.
  Future<void> createInvestmentLog(InvestmentLog log);

  /// Updates an existing investment log.
  ///
  /// Throws an exception if the investment log does not exist or cannot be updated.
  Future<void> updateInvestmentLog(InvestmentLog log);

  /// Deletes an investment log by its unique identifier.
  ///
  /// Throws an exception if the investment log does not exist or cannot be deleted.
  Future<void> deleteInvestmentLog(String id);
}

