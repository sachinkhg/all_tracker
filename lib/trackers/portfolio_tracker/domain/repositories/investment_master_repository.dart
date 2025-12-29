// lib/trackers/portfolio_tracker/domain/repositories/investment_master_repository.dart
// Abstract repository interface for investment master operations

import '../entities/investment_master.dart';

/// Abstract repository interface for investment master operations.
///
/// This interface defines the contract for investment master data access operations.
/// Implementations should handle persistence, filtering, and querying logic.
abstract class InvestmentMasterRepository {
  /// Retrieves all investment masters.
  ///
  /// Returns a list of all investment masters in the repository.
  /// Returns an empty list if no investment masters exist.
  Future<List<InvestmentMaster>> getAllInvestmentMasters();

  /// Retrieves an investment master by its unique identifier.
  ///
  /// Returns the investment master if found, null otherwise.
  Future<InvestmentMaster?> getInvestmentMasterById(String id);

  /// Retrieves an investment master by its short name.
  ///
  /// Returns the investment master if found, null otherwise.
  Future<InvestmentMaster?> getInvestmentMasterByShortName(String shortName);

  /// Creates a new investment master.
  ///
  /// Throws an exception if the investment master cannot be created.
  Future<void> createInvestmentMaster(InvestmentMaster master);

  /// Updates an existing investment master.
  ///
  /// Throws an exception if the investment master does not exist or cannot be updated.
  Future<void> updateInvestmentMaster(InvestmentMaster master);

  /// Deletes an investment master by its unique identifier.
  ///
  /// Throws an exception if the investment master does not exist or cannot be deleted.
  Future<void> deleteInvestmentMaster(String id);
}

