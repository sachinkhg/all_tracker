import 'dart:convert';
import 'dart:typed_data';
import '../../../backup/data/datasources/drive_api_client.dart';

/// Data source for Drive folder operations.
class DriveFolderDataSource {
  final DriveApiClient _driveApiClient;

  DriveFolderDataSource(this._driveApiClient);

  /// Extract folder ID from URL or return as-is if already an ID.
  String extractFolderId(String folderUrlOrId) {
    return _driveApiClient.extractFolderId(folderUrlOrId);
  }

  /// Create a folder in Drive.
  Future<String> createFolder(String folderName, {String? parentFolderId}) {
    return _driveApiClient.createFolder(folderName, parentFolderId: parentFolderId);
  }

  /// Upload a JSON file to a folder.
  Future<String> uploadJsonFile(
    String fileName,
    Map<String, dynamic> jsonData,
    String folderId,
  ) async {
    final jsonString = jsonEncode(jsonData);
    final data = utf8.encode(jsonString);
    return await _driveApiClient.uploadFileToFolder(fileName, Uint8List.fromList(data), folderId);
  }

  /// Download a JSON file from a folder.
  Future<Map<String, dynamic>> downloadJsonFile(String fileId) async {
    final data = await _driveApiClient.downloadFile(fileId);
    final jsonString = utf8.decode(data);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Find a file by name in a folder.
  Future<String?> findFile(String fileName, String folderId) {
    return _driveApiClient.findFileInFolder(fileName, folderId);
  }

  /// Get file metadata.
  Future<Map<String, dynamic>> getFileMetadata(String fileId) {
    return _driveApiClient.getFileMetadata(fileId);
  }

  /// List all files in a folder.
  Future<List<Map<String, dynamic>>> listFiles(String folderId) {
    return _driveApiClient.listFilesInFolder(folderId);
  }

  /// Move a file to a folder.
  Future<void> moveFileToFolder(String fileId, String folderId) {
    return _driveApiClient.moveFileToFolder(fileId, folderId);
  }
}

