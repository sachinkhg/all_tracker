// lib/trackers/portfolio_tracker/presentation/bloc/portfolio_cubit.dart
// Cubit for portfolio tracker state management

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../bloc/portfolio_state.dart';
import '../../data/datasources/google_sheets_data_source.dart';

/// Cubit for managing portfolio tracker state
class PortfolioCubit extends Cubit<PortfolioState> {
  final GoogleSheetsDataSource _dataSource;

  PortfolioCubit(this._dataSource) : super(const PortfolioInitial());

  /// Fetches the price for a ticker symbol from Google Sheets
  /// 
  /// [spreadsheetId] - The ID of the Google Spreadsheet
  /// [sheetName] - The name of the sheet/tab within the spreadsheet
  /// [tickerSymbol] - The ticker symbol to fetch (e.g., "AAPL")
  Future<void> fetchPrice({
    required String spreadsheetId,
    required String sheetName,
    required String tickerSymbol,
  }) async {
    if (spreadsheetId.trim().isEmpty) {
      emit(const PortfolioError('Spreadsheet ID cannot be empty'));
      return;
    }

    if (sheetName.trim().isEmpty) {
      emit(const PortfolioError('Sheet name cannot be empty'));
      return;
    }

    if (tickerSymbol.trim().isEmpty) {
      emit(const PortfolioError('Ticker symbol cannot be empty'));
      return;
    }

    emit(const PortfolioLoading());

    try {
      final price = await _dataSource.fetchTickerPrice(
        spreadsheetId: spreadsheetId.trim(),
        sheetName: sheetName.trim(),
        tickerSymbol: tickerSymbol.trim(),
      );

      if (price == null) {
        emit(PortfolioError(
          'Price not found for ticker symbol: ${tickerSymbol.toUpperCase()}. '
          'Please check that the ticker exists in your Google Sheet.',
        ));
        return;
      }

      emit(PortfolioPriceLoaded(
        tickerSymbol: tickerSymbol.toUpperCase(),
        price: price,
        fetchedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error fetching price: $e');
      final errorString = e.toString();
      
      // Check if it's an insufficient scopes error
      if (errorString.contains('insufficient authentication scopes') ||
          errorString.contains('Please sign out and sign back in')) {
        emit(PortfolioError(
          'Authentication Error: Please sign out and sign back in to grant access to Google Sheets. '
          'The app needs permission to read your spreadsheets.',
        ));
      } else if (errorString.contains('not enabled') || 
                 errorString.contains('Enable it by visiting') ||
                 errorString.contains('Google Sheets API is not enabled')) {
        emit(PortfolioError(
          'Google Sheets API is not enabled in your Google Cloud project.\n\n'
          'To fix this:\n'
          '1. Go to Google Cloud Console\n'
          '2. Enable the Google Sheets API\n'
          '3. Wait a few minutes for changes to propagate\n'
          '4. Try again\n\n'
          'Enable API: https://console.cloud.google.com/apis/library/sheets.googleapis.com',
        ));
      } else {
        emit(PortfolioError(
          'Failed to fetch price: ${e.toString()}',
        ));
      }
    }
  }

  /// Resets the state to initial
  void reset() {
    emit(const PortfolioInitial());
  }
}

