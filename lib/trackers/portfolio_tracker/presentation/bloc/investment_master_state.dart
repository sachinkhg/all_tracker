// lib/trackers/portfolio_tracker/presentation/bloc/investment_master_state.dart
// States for investment master feature

import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_master.dart';

abstract class InvestmentMasterState extends Equatable {
  const InvestmentMasterState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded
class InvestmentMastersInitial extends InvestmentMasterState {
  const InvestmentMastersInitial();
}

/// Loading state - fetching investment masters
class InvestmentMastersLoading extends InvestmentMasterState {
  const InvestmentMastersLoading();
}

/// Success state - investment masters loaded successfully
class InvestmentMastersLoaded extends InvestmentMasterState {
  final List<InvestmentMaster> investmentMasters;

  const InvestmentMastersLoaded(this.investmentMasters);

  @override
  List<Object?> get props => [investmentMasters];
}

/// Error state - error occurred while fetching
class InvestmentMastersError extends InvestmentMasterState {
  final String message;

  const InvestmentMastersError(this.message);

  @override
  List<Object?> get props => [message];
}

