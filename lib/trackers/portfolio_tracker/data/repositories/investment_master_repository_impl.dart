// lib/trackers/portfolio_tracker/data/repositories/investment_master_repository_impl.dart
// Concrete implementation of InvestmentMasterRepository

import '../../domain/entities/investment_master.dart';
import '../../domain/repositories/investment_master_repository.dart';
import '../datasources/investment_master_local_data_source.dart';
import '../models/investment_master_model.dart';

/// Concrete implementation of [InvestmentMasterRepository] using Hive for persistence.
class InvestmentMasterRepositoryImpl implements InvestmentMasterRepository {
  final InvestmentMasterLocalDataSource dataSource;

  InvestmentMasterRepositoryImpl(this.dataSource);

  @override
  Future<List<InvestmentMaster>> getAllInvestmentMasters() async {
    final models = await dataSource.getAllInvestmentMasters();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<InvestmentMaster?> getInvestmentMasterById(String id) async {
    final model = await dataSource.getInvestmentMasterById(id);
    return model?.toEntity();
  }

  @override
  Future<InvestmentMaster?> getInvestmentMasterByShortName(String shortName) async {
    try {
      final model = await dataSource.getInvestmentMasterByShortName(shortName);
      return model?.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createInvestmentMaster(InvestmentMaster master) async {
    final model = InvestmentMasterModel.fromEntity(master);
    await dataSource.createInvestmentMaster(model);
  }

  @override
  Future<void> updateInvestmentMaster(InvestmentMaster master) async {
    final model = InvestmentMasterModel.fromEntity(master);
    await dataSource.updateInvestmentMaster(model);
  }

  @override
  Future<void> deleteInvestmentMaster(String id) async {
    await dataSource.deleteInvestmentMaster(id);
  }
}

