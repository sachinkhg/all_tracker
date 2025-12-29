// lib/trackers/portfolio_tracker/presentation/bloc/portfolio_state.dart
// States for portfolio tracker feature

import 'package:equatable/equatable.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded
class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

/// Loading state - fetching price from Google Sheets
class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

/// Success state - price fetched successfully
class PortfolioPriceLoaded extends PortfolioState {
  final String tickerSymbol;
  final double price;
  final DateTime fetchedAt;

  const PortfolioPriceLoaded({
    required this.tickerSymbol,
    required this.price,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => [tickerSymbol, price, fetchedAt];
}

/// Error state - error occurred while fetching
class PortfolioError extends PortfolioState {
  final String message;

  const PortfolioError(this.message);

  @override
  List<Object?> get props => [message];
}

