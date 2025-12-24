// lib/trackers/portfolio_tracker/presentation/bloc/investment_master_cubit.dart
// Cubit for investment master state management

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/investment_master.dart';
import '../../domain/entities/investment_category.dart';
import '../../domain/entities/investment_tracking_type.dart';
import '../../domain/entities/investment_currency.dart';
import '../../domain/entities/risk_factor.dart';
import '../../domain/usecases/investment_master/get_all_investment_masters.dart';
import '../../domain/usecases/investment_master/get_investment_master_by_id.dart';
import '../../domain/usecases/investment_master/create_investment_master.dart';
import '../../domain/usecases/investment_master/update_investment_master.dart';
import '../../domain/usecases/investment_master/delete_investment_master.dart';
import '../bloc/investment_master_state.dart';

/// Cubit for managing investment master state
class InvestmentMasterCubit extends Cubit<InvestmentMasterState> {
  final GetAllInvestmentMasters getAll;
  final GetInvestmentMasterById getById;
  final CreateInvestmentMaster create;
  final UpdateInvestmentMaster update;
  final DeleteInvestmentMaster delete;

  InvestmentMasterCubit({
    required this.getAll,
    required this.getById,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(const InvestmentMastersInitial());

  /// Loads all investment masters from the repository.
  Future<void> loadInvestmentMasters() async {
    emit(const InvestmentMastersLoading());
    try {
      final masters = await getAll();
      emit(InvestmentMastersLoaded(masters));
    } catch (e) {
      emit(InvestmentMastersError('Failed to load investment masters: $e'));
    }
  }

  /// Gets an investment master by its ID.
  Future<InvestmentMaster?> getInvestmentMasterById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(InvestmentMastersError('Failed to get investment master: $e'));
      return null;
    }
  }

  /// Creates a new investment master.
  Future<void> createInvestmentMaster({
    required String shortName,
    required String name,
    required InvestmentCategory investmentCategory,
    required InvestmentTrackingType investmentTrackingType,
    required InvestmentCurrency investmentCurrency,
    required RiskFactor riskFactor,
  }) async {
    try {
      final now = DateTime.now();
      final master = InvestmentMaster(
        id: const Uuid().v4(),
        shortName: shortName,
        name: name,
        investmentCategory: investmentCategory,
        investmentTrackingType: investmentTrackingType,
        investmentCurrency: investmentCurrency,
        riskFactor: riskFactor,
        createdAt: now,
        updatedAt: now,
      );

      await create(master);
      await loadInvestmentMasters(); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentMastersError('Failed to create investment master: $e'));
    }
  }

  /// Updates an existing investment master.
  Future<void> updateInvestmentMaster(InvestmentMaster master) async {
    try {
      final updated = master.copyWith(updatedAt: DateTime.now());
      await update(updated);
      await loadInvestmentMasters(); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentMastersError('Failed to update investment master: $e'));
    }
  }

  /// Deletes an investment master.
  Future<void> deleteInvestmentMaster(String id) async {
    try {
      await delete(id);
      await loadInvestmentMasters(); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentMastersError('Failed to delete investment master: $e'));
    }
  }
}

