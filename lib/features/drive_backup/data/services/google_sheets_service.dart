import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import '../../../backup/data/datasources/google_auth_datasource.dart';

/// Service for interacting with Google Sheets API.
/// 
/// Handles creating spreadsheets, appending rows, and reading data.
class GoogleSheetsService {
  final GoogleAuthDataSource _authDataSource;

  GoogleSheetsService(this._authDataSource);

  /// Get authenticated HTTP client for Google APIs.
  Future<http.Client> _getAuthenticatedClient() async {
    final accessToken = await _authDataSource.getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    return _AuthenticatedClient(accessToken);
  }

  /// Create a new spreadsheet.
  /// 
  /// [title]: The title of the spreadsheet
  /// [parentFolderId]: Optional folder ID to create the spreadsheet in
  /// 
  /// Returns the spreadsheet ID.
  Future<String> createSpreadsheet(String title, {String? parentFolderId}) async {
    print('[Google Sheets] Creating spreadsheet: $title${parentFolderId != null ? ' in folder: $parentFolderId' : ''}');
    
    final accessToken = await _authDataSource.getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    // Create spreadsheet using Drive API with parents property
    // This ensures it's created in the correct folder from the start
    final fileMetadata = <String, dynamic>{
      'name': title,
      'mimeType': 'application/vnd.google-apps.spreadsheet',
    };
    
    if (parentFolderId != null) {
      fileMetadata['parents'] = [parentFolderId];
    }

    print('[Google Sheets] Creating file with metadata: $fileMetadata');

    final createResponse = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(fileMetadata),
    );

    if (createResponse.statusCode != 200) {
      print('[Google Sheets] Failed to create spreadsheet: ${createResponse.body}');
      throw Exception('Failed to create spreadsheet: ${createResponse.body}');
    }

    final responseData = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final spreadsheetId = responseData['id'] as String? ?? '';
    
    print('[Google Sheets] Created spreadsheet with ID: $spreadsheetId');
    print('[Google Sheets] Spreadsheet URL: https://docs.google.com/spreadsheets/d/$spreadsheetId');
    
    return spreadsheetId;
  }

  /// Append rows to a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  /// [rows]: List of rows to append (each row is a list of values)
  Future<void> appendRows(
    String spreadsheetId,
    List<List<Object?>> rows, {
    String sheetName = 'Sheet1',
  }) async {
    if (rows.isEmpty) {
      print('[Google Sheets] No rows to append');
      return;
    }

    print('[Google Sheets] Appending ${rows.length} rows to spreadsheet $spreadsheetId, sheet: $sheetName');
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      final valueRange = sheets.ValueRange()
        ..values = rows;

      final response = await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        '$sheetName!A:Z',
        valueInputOption: 'USER_ENTERED',
      );
      
      print('[Google Sheets] Append response: ${response.updates?.updatedRows ?? 0} rows updated');
    } catch (e, stackTrace) {
      print('[Google Sheets] Error appending rows: $e');
      print('[Google Sheets] Stack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Read all rows from a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  /// 
  /// Returns a list of rows (each row is a list of values).
  Future<List<List<Object?>>> readAllRows(
    String spreadsheetId, {
    String sheetName = 'Sheet1',
  }) async {
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        '$sheetName!A:Z',
      );

      return response.values ?? [];
    } finally {
      client.close();
    }
  }

  /// Get the last modified time of a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// 
  /// Returns the modified time as a DateTime, or null if not available.
  /// 
  /// Note: Google Sheets API doesn't directly provide modifiedTime.
  /// This should be handled by comparing file metadata from Drive API.
  Future<DateTime?> getLastModifiedTime(String spreadsheetId) async {
    // Note: Google Sheets API doesn't directly provide modifiedTime
    // We'll use the Drive API for this, but for now return null
    // This will be handled by comparing file metadata from Drive
    return null;
  }

  /// Clear all data from a sheet (except headers).
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  /// [headerRowCount]: Number of header rows to preserve (default: 1)
  Future<void> clearSheet(
    String spreadsheetId, {
    String sheetName = 'Sheet1',
    int headerRowCount = 1,
  }) async {
    print('[Google Sheets] Clearing sheet: $spreadsheetId, sheet: $sheetName, preserving $headerRowCount header rows');
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      // Read headers if needed
      List<List<Object?>>? headers;
      if (headerRowCount > 0) {
        try {
          final headerResponse = await sheetsApi.spreadsheets.values.get(
            spreadsheetId,
            '$sheetName!1:$headerRowCount',
          );
          headers = headerResponse.values;
          print('[Google Sheets] Read ${headers?.length ?? 0} header rows');
        } catch (e) {
          // If headers don't exist yet, that's okay
          print('[Google Sheets] No existing headers found (this is okay for new sheets)');
          headers = null;
        }
      }

      // Clear all data
      print('[Google Sheets] Clearing all data from sheet');
      final clearResponse = await sheetsApi.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        spreadsheetId,
        '$sheetName!A:Z',
      );
      print('[Google Sheets] Cleared ${clearResponse.clearedRange ?? 'unknown'} cells');

      // Restore headers if they exist
      if (headers != null && headers.isNotEmpty) {
        print('[Google Sheets] Restoring ${headers.length} header rows');
        final valueRange = sheets.ValueRange()..values = headers;
        await sheetsApi.spreadsheets.values.update(
          valueRange,
          spreadsheetId,
          '$sheetName!1:$headerRowCount',
          valueInputOption: 'USER_ENTERED',
        );
        print('[Google Sheets] Headers restored');
      } else {
        print('[Google Sheets] No headers to restore');
      }
    } catch (e, stackTrace) {
      print('[Google Sheets] Error clearing sheet: $e');
      print('[Google Sheets] Stack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }
}

/// HTTP client that adds Authorization header with access token.
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

