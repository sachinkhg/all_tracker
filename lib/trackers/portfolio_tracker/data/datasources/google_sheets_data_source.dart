// lib/trackers/portfolio_tracker/data/datasources/google_sheets_data_source.dart
// Data source for reading ticker prices from Google Sheets

import 'package:flutter/foundation.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import '../../../../features/backup/data/datasources/google_auth_datasource.dart';
import '../../core/constants.dart';

/// Data source for reading data from Google Sheets.
/// 
/// Uses Google Sheets API v4 to read ticker prices from a spreadsheet.
/// Assumes the sheet has ticker symbols in column A and prices in column B.
class GoogleSheetsDataSource {
  final GoogleAuthDataSource _authDataSource;

  GoogleSheetsDataSource(this._authDataSource);

  /// Fetches the price for a given ticker symbol from a Google Sheet.
  /// 
  /// [spreadsheetId] - The ID of the Google Spreadsheet (from the URL)
  /// [sheetName] - The name of the sheet/tab within the spreadsheet
  /// [tickerSymbol] - The ticker symbol to search for (e.g., "AAPL")
  /// 
  /// Returns the price as a double, or null if not found or on error.
  Future<double?> fetchTickerPrice({
    required String spreadsheetId,
    required String sheetName,
    required String tickerSymbol,
  }) async {
    try {
      // Get access token from Google Auth
      final accessToken = await _authDataSource.getAccessToken();
      if (accessToken == null) {
        debugPrint('No access token available. User may need to sign in.');
        return null;
      }

      // Create authenticated HTTP client that adds Authorization header
      final authClient = _AuthenticatedClient(accessToken);

      // Create Sheets API client
      final sheetsApi = sheets.SheetsApi(authClient);

      // Read the sheet to find the ticker symbol
      // We'll read columns A and B to find the ticker and get its price
      final range = '$sheetName!${PortfolioTrackerConstants.defaultTickerColumn}:${PortfolioTrackerConstants.defaultPriceColumn}';
      
      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        range,
      );

      if (response.values == null || response.values!.isEmpty) {
        debugPrint('No data found in sheet');
        return null;
      }

      // Search for the ticker symbol in column A
      // Skip first row if it's a header
      final rows = response.values!;
      final startRow = _hasHeader(rows) ? 1 : 0;

      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty) {
          final ticker = row[0]?.toString().trim().toUpperCase();
          if (ticker == tickerSymbol.toUpperCase()) {
            // Found the ticker, get the price from column B
            if (row.length > 1 && row[1] != null) {
              final priceStr = row[1].toString().trim();
              final price = double.tryParse(priceStr);
              if (price != null) {
                debugPrint('Found price for $tickerSymbol: $price');
                return price;
              } else {
                debugPrint('Invalid price format for $tickerSymbol: $priceStr');
              }
            } else {
              debugPrint('No price found for ticker $tickerSymbol');
            }
          }
        }
      }

      debugPrint('Ticker symbol $tickerSymbol not found in sheet');
      return null;
    } on sheets.DetailedApiRequestError catch (e) {
      // Handle API-specific errors
      final errorMessage = e.message ?? '';
      
      if (e.status == 403) {
        if (errorMessage.contains('insufficient authentication scopes')) {
          debugPrint('Insufficient authentication scopes. User needs to re-authenticate with Sheets scope.');
          // Clear cached token to force re-authentication
          _authDataSource.clearCachedToken();
          throw _InsufficientScopesException(
            'Please sign out and sign back in to grant access to Google Sheets. '
            'The app needs permission to read your spreadsheets.',
          );
        } else if (errorMessage.contains('has not been used') || 
                   errorMessage.contains('is disabled') ||
                   errorMessage.contains('Enable it by visiting')) {
          debugPrint('Google Sheets API is not enabled in the project.');
          throw _ApiNotEnabledException(
            'Google Sheets API is not enabled in your Google Cloud project. '
            'Please enable it in the Google Cloud Console:\n'
            'https://console.cloud.google.com/apis/library/sheets.googleapis.com',
          );
        }
      }
      debugPrint('Google Sheets API error: ${e.status} - $errorMessage');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error fetching ticker price: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Checks if the first row looks like a header (non-numeric values)
  bool _hasHeader(List<List<Object?>> rows) {
    if (rows.isEmpty) return false;
    final firstRow = rows[0];
    if (firstRow.isEmpty) return false;
    
    // If first cell is not a number, assume it's a header
    final firstCell = firstRow[0]?.toString().trim() ?? '';
    return double.tryParse(firstCell) == null;
  }
}

/// Exception thrown when user needs to re-authenticate with additional scopes
class _InsufficientScopesException implements Exception {
  final String message;
  _InsufficientScopesException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when Google Sheets API is not enabled in the project
class _ApiNotEnabledException implements Exception {
  final String message;
  _ApiNotEnabledException(this.message);
  
  @override
  String toString() => message;
}

/// HTTP client that adds Authorization header with access token
class _AuthenticatedClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

