import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'google_auth_datasource.dart';

/// Client for interacting with the Google Drive API.
/// 
/// Implements methods for uploading, listing, downloading, and deleting files
/// in the appDataFolder space.
class DriveApiClient {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3';

  final GoogleAuthDataSource _authDataSource;

  DriveApiClient(this._authDataSource);

  /// Get access token for API calls.
  Future<String?> _getAccessToken() async {
    return await _authDataSource.getAccessToken();
  }

  /// Upload a file to the Drive appDataFolder.
  /// 
  /// [fileName]: The name of the backup file
  /// [data]: The file data to upload
  /// [appProperties]: Custom metadata to attach to the file
  /// 
  /// Returns the file ID of the uploaded file.
  /// 
  /// Throws [Exception] if upload fails.
  Future<String> uploadFile(
    String fileName,
    Uint8List data,
    Map<String, String> appProperties,
  ) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    // Step 1: Initiate resumable upload
    final metadata = {
      'name': fileName,
      'parents': ['appDataFolder'],
      'appProperties': appProperties,
    };

    final initResponse = await http.post(
      Uri.parse('$_uploadUrl/files?uploadType=resumable'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(metadata),
    );

    if (initResponse.statusCode != 200) {
      throw Exception('Failed to initiate upload: ${initResponse.body}');
    }

    final uploadUrl = initResponse.headers['location'];
    if (uploadUrl == null) {
      throw Exception('No upload URL received');
    }

    // Step 2: Upload the file data
    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': data.length.toString(),
      },
      body: data,
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception('Upload failed: ${uploadResponse.body}');
    }

    final responseData = jsonDecode(uploadResponse.body) as Map<String, dynamic>;
    return responseData['id'] as String;
  }

  /// List all backup files in the appDataFolder.
  /// 
  /// Returns a list of file metadata.
  Future<List<Map<String, dynamic>>> listBackups() async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/files?spaces=appDataFolder&fields=files(id,name,size,createdTime,appProperties,modifiedTime)'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list backups: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];
    
    return files.cast<Map<String, dynamic>>();
  }

  /// Download a file from Drive.
  /// 
  /// [fileId]: The ID of the file to download
  /// 
  /// Returns the file data.
  Future<Uint8List> downloadFile(String fileId) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/files/$fileId?alt=media'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.body}');
    }

    return response.bodyBytes;
  }

  /// Delete a file from Drive.
  /// 
  /// [fileId]: The ID of the file to delete
  Future<void> deleteFile(String fileId) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }
}

