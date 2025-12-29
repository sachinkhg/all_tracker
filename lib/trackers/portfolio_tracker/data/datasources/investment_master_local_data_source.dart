// lib/trackers/portfolio_tracker/data/datasources/investment_master_local_data_source.dart
// Hive-backed local data source for InvestmentMaster objects

import 'package:hive/hive.dart';
import '../models/investment_master_model.dart';

/// Abstract data source for local (Hive) investment master storage.
///
/// Implementations should be simple adapters that read/write InvestmentMasterModel instances.
/// Conversions between domain entity and DTO should be implemented in InvestmentMasterModel.
abstract class InvestmentMasterLocalDataSource {
  /// Returns all investment masters stored in the local box.
  Future<List<InvestmentMasterModel>> getAllInvestmentMasters();

  /// Returns a single InvestmentMasterModel by its string id key, or null if not found.
  Future<InvestmentMasterModel?> getInvestmentMasterById(String id);

  /// Returns an investment master by short name, or null if not found.
  Future<InvestmentMasterModel?> getInvestmentMasterByShortName(String shortName);

  /// Persists a new InvestmentMasterModel. The implementation is expected to use master.id as key.
  Future<void> createInvestmentMaster(InvestmentMasterModel master);

  /// Updates an existing InvestmentMasterModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateInvestmentMaster(InvestmentMasterModel master);

  /// Deletes an investment master by its id key.
  Future<void> deleteInvestmentMaster(String id);
}

/// Hive implementation of [InvestmentMasterLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// InvestmentMasterModel persistence. It uses `master.id` (String) as the Hive key.
class InvestmentMasterLocalDataSourceImpl implements InvestmentMasterLocalDataSource {
  /// Hive box that stores [InvestmentMasterModel] entries.
  final Box<InvestmentMasterModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the InvestmentMasterModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  InvestmentMasterLocalDataSourceImpl(this.box);

  @override
  Future<void> createInvestmentMaster(InvestmentMasterModel master) async {
    await box.put(master.id, master);
  }

  @override
  Future<void> deleteInvestmentMaster(String id) async {
    await box.delete(id);
  }

  @override
  Future<InvestmentMasterModel?> getInvestmentMasterById(String id) async {
    return box.get(id);
  }

  @override
  Future<InvestmentMasterModel?> getInvestmentMasterByShortName(String shortName) async {
    final allMasters = box.values.toList();
    return allMasters.firstWhere(
      (master) => master.shortName.toLowerCase() == shortName.toLowerCase(),
      orElse: () => throw StateError('Investment master not found'),
    );
  }

  @override
  Future<List<InvestmentMasterModel>> getAllInvestmentMasters() async {
    return box.values.toList();
  }

  @override
  Future<void> updateInvestmentMaster(InvestmentMasterModel master) async {
    await box.put(master.id, master);
  }
}

