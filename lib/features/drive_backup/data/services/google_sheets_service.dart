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

  /// Update specific cells in a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [range]: The A1 notation range (e.g., 'Sheet1!K2:K10' for column K, rows 2-10)
  /// [values]: List of rows, where each row is a list of values
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  Future<void> updateCells(
    String spreadsheetId,
    String range,
    List<List<Object?>> values, {
    String sheetName = 'Sheet1',
  }) async {
    print('[Google Sheets] Updating cells in range: $range');
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      final valueRange = sheets.ValueRange()
        ..values = values;

      final response = await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
      
      print('[Google Sheets] Updated ${response.updatedCells ?? 0} cells');
    } catch (e, stackTrace) {
      print('[Google Sheets] Error updating cells: $e');
      print('[Google Sheets] Stack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Update a specific row in a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [rowNumber]: The row number to update (1-based, where 1 is the first row)
  /// [values]: List of values for the row (will update entire row)
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  Future<void> updateRow(
    String spreadsheetId,
    int rowNumber,
    List<Object?> values, {
    String sheetName = 'Sheet1',
  }) async {
    print('[Google Sheets] Updating row $rowNumber in spreadsheet $spreadsheetId');
    final range = '$sheetName!$rowNumber:$rowNumber';
    await updateCells(spreadsheetId, range, [values], sheetName: sheetName);
  }

  /// Update specific cells in a row.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [rowNumber]: The row number to update (1-based, where 1 is the first row)
  /// [columnIndex]: The starting column index (0-based, where 0 is column A)
  /// [values]: List of values to update (will update consecutive columns)
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  Future<void> updateRowCells(
    String spreadsheetId,
    int rowNumber,
    int columnIndex,
    List<Object?> values, {
    String sheetName = 'Sheet1',
  }) async {
    if (values.isEmpty) return;
    
    // Convert column index to letter (0=A, 1=B, ..., 25=Z)
    // For columns beyond Z, we'd need AA, AB, etc., but for our use case (11 columns max), we don't need that
    String columnLetter(int index) {
      if (index < 26) {
        return String.fromCharCode(65 + index); // A-Z
      } else {
        // Handle AA, AB, etc. (not needed for our 11 columns, but included for completeness)
        final first = String.fromCharCode(64 + (index ~/ 26));
        final second = String.fromCharCode(65 + (index % 26));
        return first + second;
      }
    }
    
    final startColumn = columnLetter(columnIndex);
    final endColumnIndex = columnIndex + values.length - 1;
    final endColumn = columnLetter(endColumnIndex);
    
    final range = '$sheetName!$startColumn$rowNumber:$endColumn$rowNumber';
    print('[Google Sheets] Updating cells in row $rowNumber, columns $startColumn-$endColumn');
    await updateCells(spreadsheetId, range, [values], sheetName: sheetName);
  }

  /// Delete specific rows from a spreadsheet.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [rowNumbers]: List of row numbers to delete (1-based, where 1 is the first row)
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  /// 
  /// Note: Rows should be provided in descending order to avoid index shifting issues.
  Future<void> deleteRows(
    String spreadsheetId,
    List<int> rowNumbers, {
    String sheetName = 'Sheet1',
  }) async {
    if (rowNumbers.isEmpty) {
      print('[Google Sheets] No rows to delete');
      return;
    }

    print('[Google Sheets] Deleting ${rowNumbers.length} rows from spreadsheet $spreadsheetId, sheet: $sheetName');
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      // Sort row numbers in descending order to avoid index shifting
      final sortedRowNumbers = List<int>.from(rowNumbers)..sort((a, b) => b.compareTo(a));

      // Create batch update request with delete dimension requests
      final requests = <sheets.Request>[];
      for (final rowNumber in sortedRowNumbers) {
        final dimensionRange = sheets.DimensionRange()
          ..sheetId = 0 // First sheet (Sheet1)
          ..dimension = 'ROWS'
          ..startIndex = rowNumber - 1 // Convert 1-based to 0-based
          ..endIndex = rowNumber; // End index is exclusive (0-based)
        
        final deleteDimensionRequest = sheets.DeleteDimensionRequest()
          ..range = dimensionRange;
        
        final request = sheets.Request()
          ..deleteDimension = deleteDimensionRequest;
        
        requests.add(request);
      }

      final batchUpdateRequest = sheets.BatchUpdateSpreadsheetRequest()
        ..requests = requests;

      final response = await sheetsApi.spreadsheets.batchUpdate(
        batchUpdateRequest,
        spreadsheetId,
      );

      print('[Google Sheets] Deleted ${response.replies?.length ?? 0} rows');
    } catch (e, stackTrace) {
      print('[Google Sheets] Error deleting rows: $e');
      print('[Google Sheets] Stack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Format the spreadsheet with header colors, fonts, and data validation.
  /// 
  /// [spreadsheetId]: The ID of the spreadsheet
  /// [sheetName]: The name of the sheet/tab (default: 'Sheet1')
  Future<void> formatSheet(String spreadsheetId, {String sheetName = 'Sheet1'}) async {
    print('[Google Sheets] Formatting sheet: $spreadsheetId');
    final client = await _getAuthenticatedClient();
    try {
      final sheetsApi = sheets.SheetsApi(client);

      // Get the sheet ID
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final sheetsList = spreadsheet.sheets;
      if (sheetsList == null || sheetsList.isEmpty) {
        throw Exception('No sheets found in spreadsheet');
      }
      
      final sheet = sheetsList.firstWhere(
        (s) => s.properties?.title == sheetName,
        orElse: () => sheetsList.first,
      );
      
      final sheetId = sheet.properties?.sheetId;
      if (sheetId == null) {
        throw Exception('Sheet not found: $sheetName');
      }
      
      final requests = <sheets.Request>[];

      // 1. Format header row (row 1) with background color
      final headerRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 0
        ..endRowIndex = 1
        ..startColumnIndex = 0
        ..endColumnIndex = 11; // All 11 columns (0-10)
      
      final headerBackgroundColor = sheets.Color()
        ..red = 0.2 // Dark blue-gray
        ..green = 0.4
        ..blue = 0.6;
      
      final headerTextColor = sheets.Color()
        ..red = 1.0 // White text
        ..green = 1.0
        ..blue = 1.0;
      
      final headerTextFormat = sheets.TextFormat()
        ..foregroundColor = headerTextColor
        ..fontSize = 11
        ..bold = true;
      
      final headerCellFormat = sheets.CellFormat()
        ..backgroundColor = headerBackgroundColor
        ..textFormat = headerTextFormat;
      
      final headerCellData = sheets.CellData()
        ..userEnteredFormat = headerCellFormat;
      
      final headerRepeatCellRequest = sheets.RepeatCellRequest()
        ..range = headerRange
        ..cell = headerCellData
        ..fields = 'userEnteredFormat(backgroundColor,textFormat(foregroundColor,fontSize,bold))';
      
      requests.add(sheets.Request()
        ..repeatCell = headerRepeatCellRequest);

      // 2. Format all cells with Open Sans font
      final fontRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 0
        ..endRowIndex = 1000 // Format first 1000 rows
        ..startColumnIndex = 0
        ..endColumnIndex = 11;
      
      final fontTextFormat = sheets.TextFormat()
        ..fontFamily = 'Open Sans'
        ..fontSize = 10;
      
      final fontCellFormat = sheets.CellFormat()
        ..textFormat = fontTextFormat;
      
      final fontCellData = sheets.CellData()
        ..userEnteredFormat = fontCellFormat;
      
      final fontRepeatCellRequest = sheets.RepeatCellRequest()
        ..range = fontRange
        ..cell = fontCellData
        ..fields = 'userEnteredFormat.textFormat(fontFamily,fontSize)';
      
      requests.add(sheets.Request()
        ..repeatCell = fontRepeatCellRequest);

      // 3. Format read-only columns (Book ID, Created At, Updated At) with light gray background
      // Book ID (column A, index 0)
      final bookIdRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 1 // Start from row 2 (skip header)
        ..endRowIndex = 1000
        ..startColumnIndex = 0
        ..endColumnIndex = 1;
      
      final readOnlyBackgroundColor = sheets.Color()
        ..red = 0.95 // Very light gray
        ..green = 0.95
        ..blue = 0.95;
      
      final readOnlyCellFormat = sheets.CellFormat()
        ..backgroundColor = readOnlyBackgroundColor;
      
      final readOnlyCellData = sheets.CellData()
        ..userEnteredFormat = readOnlyCellFormat;
      
      final bookIdRepeatCellRequest = sheets.RepeatCellRequest()
        ..range = bookIdRange
        ..cell = readOnlyCellData
        ..fields = 'userEnteredFormat.backgroundColor';
      
      requests.add(sheets.Request()
        ..repeatCell = bookIdRepeatCellRequest);
      
      // Created At (column I, index 8)
      final createdAtRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 1
        ..endRowIndex = 1000
        ..startColumnIndex = 8
        ..endColumnIndex = 9;
      
      final createdAtRepeatCellRequest = sheets.RepeatCellRequest()
        ..range = createdAtRange
        ..cell = readOnlyCellData
        ..fields = 'userEnteredFormat.backgroundColor';
      
      requests.add(sheets.Request()
        ..repeatCell = createdAtRepeatCellRequest);
      
      // Updated At (column J, index 9)
      final updatedAtRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 1
        ..endRowIndex = 1000
        ..startColumnIndex = 9
        ..endColumnIndex = 10;
      
      final updatedAtRepeatCellRequest = sheets.RepeatCellRequest()
        ..range = updatedAtRange
        ..cell = readOnlyCellData
        ..fields = 'userEnteredFormat.backgroundColor';
      
      requests.add(sheets.Request()
        ..repeatCell = updatedAtRepeatCellRequest);

      // 4. Add dropdown validation to Action column (column K, index 10)
      final validationRange = sheets.GridRange()
        ..sheetId = sheetId
        ..startRowIndex = 1 // Start from row 2 (skip header)
        ..endRowIndex = 1000 // Apply to first 1000 data rows
        ..startColumnIndex = 10 // Column K (Action column)
        ..endColumnIndex = 11;
      
      final conditionValues = [
        sheets.ConditionValue()..userEnteredValue = '',
        sheets.ConditionValue()..userEnteredValue = 'CREATE BOOK',
        sheets.ConditionValue()..userEnteredValue = 'UPDATE BOOK',
        sheets.ConditionValue()..userEnteredValue = 'DELETE BOOK',
        sheets.ConditionValue()..userEnteredValue = 'CREATE REREAD',
        sheets.ConditionValue()..userEnteredValue = 'UPDATE REREAD',
        sheets.ConditionValue()..userEnteredValue = 'DELETE REREAD',
      ];
      
      final booleanCondition = sheets.BooleanCondition()
        ..type = 'ONE_OF_LIST'
        ..values = conditionValues;
      
      final dataValidationRule = sheets.DataValidationRule()
        ..condition = booleanCondition
        ..showCustomUi = true
        ..strict = false; // Allow empty values
      
      final setDataValidationRequest = sheets.SetDataValidationRequest()
        ..range = validationRange
        ..rule = dataValidationRule;
      
      requests.add(sheets.Request()
        ..setDataValidation = setDataValidationRequest);

      // Execute batch update
      final batchUpdateRequest = sheets.BatchUpdateSpreadsheetRequest()
        ..requests = requests;

      final response = await sheetsApi.spreadsheets.batchUpdate(
        batchUpdateRequest,
        spreadsheetId,
      );

      print('[Google Sheets] Applied formatting: ${response.replies?.length ?? 0} requests processed');
    } catch (e, stackTrace) {
      print('[Google Sheets] Error formatting sheet: $e');
      print('[Google Sheets] Stack trace: $stackTrace');
      rethrow;
    } finally {
      client.close();
    }
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

