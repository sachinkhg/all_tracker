import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing photo file storage on device.
///
/// Stores photos in app's documents directory under a 'travel_photos' folder.
/// Returns file paths that are stored in Photo entities.
class PhotoStorageService {
  /// Get the directory where photos are stored.
  Future<Directory> _getPhotoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/travel_photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Save a photo file and return its path.
  ///
  /// [sourcePath] - path to the source image file
  /// [photoId] - unique identifier for the photo (used in filename)
  Future<String> savePhoto(String sourcePath, String photoId) async {
    final photoDir = await _getPhotoDirectory();
    final sourceFile = File(sourcePath);
    final extension = sourcePath.split('.').last;
    final fileName = '$photoId.$extension';
    final destFile = File('${photoDir.path}/$fileName');

    await sourceFile.copy(destFile.path);
    return destFile.path;
  }

  /// Delete a photo file by its path.
  Future<void> deletePhoto(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Check if a photo file exists.
  Future<bool> photoExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Get a File object for a photo path.
  File getPhotoFile(String filePath) {
    return File(filePath);
  }
}

