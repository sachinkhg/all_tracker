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

  /// Extract folder ID from a Google Drive URL or return the ID if already provided.
  /// 
  /// Supports formats:
  /// - https://drive.google.com/drive/folders/FOLDER_ID
  /// - https://drive.google.com/drive/u/0/folders/FOLDER_ID
  /// - FOLDER_ID (if already an ID)
  String extractFolderId(String folderUrlOrId) {
    // If it's already just an ID (no slashes), return it
    if (!folderUrlOrId.contains('/')) {
      return folderUrlOrId;
    }

    // Extract ID from URL
    final uri = Uri.parse(folderUrlOrId);
    final pathSegments = uri.pathSegments;
    
    // Look for 'folders' segment and get the next segment as ID
    final foldersIndex = pathSegments.indexOf('folders');
    if (foldersIndex != -1 && foldersIndex < pathSegments.length - 1) {
      return pathSegments[foldersIndex + 1];
    }

    // If no 'folders' segment found, try to extract from query parameters
    final id = uri.queryParameters['id'];
    if (id != null) {
      return id;
    }

    throw Exception('Invalid folder URL or ID: $folderUrlOrId');
  }

  /// Create a folder in Google Drive.
  /// 
  /// [folderName]: The name of the folder to create
  /// [parentFolderId]: Optional parent folder ID. If null, creates in root.
  /// 
  /// Returns the folder ID.
  Future<String> createFolder(String folderName, {String? parentFolderId}) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final metadata = {
      'name': folderName,
      'mimeType': 'application/vnd.google-apps.folder',
      if (parentFolderId != null) 'parents': [parentFolderId],
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(metadata),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create folder: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return responseData['id'] as String;
  }

  /// Upload a file to a specific folder in Drive (user-visible).
  /// 
  /// [fileName]: The name of the file
  /// [data]: The file data to upload
  /// [folderId]: The ID of the folder to upload to
  /// 
  /// Returns the file ID of the uploaded file.
  Future<String> uploadFileToFolder(
    String fileName,
    Uint8List data,
    String folderId,
  ) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    // Step 1: Initiate resumable upload
    final metadata = {
      'name': fileName,
      'parents': [folderId],
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

  /// List files in a specific folder.
  /// 
  /// [folderId]: The ID of the folder to list files from
  /// 
  /// Returns a list of file metadata.
  Future<List<Map<String, dynamic>>> listFilesInFolder(String folderId) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/files?q="$folderId" in parents&fields=files(id,name,size,createdTime,modifiedTime,mimeType)'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];
    
    return files.cast<Map<String, dynamic>>();
  }

  /// Get file metadata by ID.
  /// 
  /// [fileId]: The ID of the file
  /// 
  /// Returns file metadata including modifiedTime.
  Future<Map<String, dynamic>> getFileMetadata(String fileId) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/files/$fileId?fields=id,name,size,createdTime,modifiedTime,mimeType,parents'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get file metadata: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data;
  }

  /// Find a file by name in a folder.
  /// 
  /// [fileName]: The name of the file to find
  /// [folderId]: The ID of the folder to search in
  /// 
  /// Returns the file ID if found, null otherwise.
  Future<String?> findFileInFolder(String fileName, String folderId) async {
    final files = await listFilesInFolder(folderId);
    for (final file in files) {
      if (file['name'] == fileName) {
        return file['id'] as String;
      }
    }
    return null;
  }

  /// Move a file to a folder.
  /// 
  /// [fileId]: The ID of the file to move
  /// [folderId]: The ID of the destination folder
  /// [removeFromPreviousParents]: Whether to remove from previous parent folders (default: true)
  Future<void> moveFileToFolder(
    String fileId,
    String folderId, {
    bool removeFromPreviousParents = true,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    print('[Drive API] Moving file $fileId to folder $folderId');

    // First, get the file's current parents
    final fileMetadata = await getFileMetadata(fileId);
    final previousParents = fileMetadata['parents'] as List<dynamic>? ?? [];
    print('[Drive API] File current parents: $previousParents');

    // Prepare the update request
    final updateData = <String, dynamic>{
      'addParents': folderId,
    };

    if (removeFromPreviousParents && previousParents.isNotEmpty) {
      // Convert list to comma-separated string
      updateData['removeParents'] = previousParents.map((p) => p.toString()).join(',');
      print('[Drive API] Removing from previous parents: ${updateData['removeParents']}');
    }

    // Prepare the update request body
    // According to Google Drive API, addParents and removeParents should be arrays
    final updateBody = <String, dynamic>{
      'addParents': [folderId],
    };

    if (removeFromPreviousParents && previousParents.isNotEmpty) {
      // Convert to list of strings
      updateBody['removeParents'] = previousParents.map((p) => p.toString()).toList();
    }

    print('[Drive API] Update body: $updateBody');

    final response = await http.patch(
      Uri.parse('$_baseUrl/files/$fileId?fields=id,parents'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updateBody),
    );

    print('[Drive API] Move response status: ${response.statusCode}');
    print('[Drive API] Move response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to move file: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final newParents = responseData['parents'] as List<dynamic>? ?? [];
    print('[Drive API] File new parents: $newParents');
  }
}

