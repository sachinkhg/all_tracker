import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Service for caching file thumbnails to avoid regenerating them on every load.
///
/// This service provides persistent caching for video thumbnails and improves
/// performance by storing generated thumbnails locally and reusing them.
class ThumbnailCacheService {
  static ThumbnailCacheService? _instance;
  Directory? _cacheDirectory;
  bool _initialized = false;

  /// Singleton instance of the cache service.
  static ThumbnailCacheService get instance {
    _instance ??= ThumbnailCacheService._();
    return _instance!;
  }

  ThumbnailCacheService._();

  /// Initializes the cache directory.
  /// Should be called before using the cache service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final cacheDir = await getTemporaryDirectory();
      _cacheDirectory = Directory('${cacheDir.path}/file_tracker_thumbnails');
      
      // Create the directory if it doesn't exist
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
      
      _initialized = true;
    } catch (e) {
      // If initialization fails, the cache will be disabled
      _cacheDirectory = null;
      _initialized = false;
    }
  }

  /// Generates a cache key from a stable identifier.
  ///
  /// Uses SHA-256 hash to create a safe filename from the identifier.
  String _generateCacheKey(String stableIdentifier) {
    final bytes = utf8.encode(stableIdentifier);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets the cached thumbnail file path for a given stable identifier.
  ///
  /// Returns null if the cache doesn't exist or hasn't been initialized.
  Future<String?> getCachedThumbnailPath(String stableIdentifier) async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return null;
    }

    final cacheKey = _generateCacheKey(stableIdentifier);
    final cachedFile = File('${_cacheDirectory!.path}/$cacheKey.png');

    // Check if the cached file exists
    if (await cachedFile.exists()) {
      return cachedFile.path;
    }

    return null;
  }

  /// Gets the cached thumbnail bytes for a given stable identifier.
  ///
  /// Returns null if the cache doesn't exist.
  Future<Uint8List?> getCachedThumbnailBytes(String stableIdentifier) async {
    final cachedPath = await getCachedThumbnailPath(stableIdentifier);
    if (cachedPath == null) return null;

    try {
      final file = File(cachedPath);
      return await file.readAsBytes();
    } catch (e) {
      // If reading fails, return null to trigger regeneration
      return null;
    }
  }

  /// Caches thumbnail bytes for a given stable identifier.
  ///
  /// Returns the path to the cached file, or null if caching failed.
  Future<String?> cacheThumbnail(
    String stableIdentifier,
    Uint8List thumbnailBytes,
  ) async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return null;
    }

    try {
      final cacheKey = _generateCacheKey(stableIdentifier);
      final cachedFile = File('${_cacheDirectory!.path}/$cacheKey.png');
      
      await cachedFile.writeAsBytes(thumbnailBytes);
      return cachedFile.path;
    } catch (e) {
      // If caching fails, return null
      return null;
    }
  }

  /// Caches thumbnail from a file path.
  ///
  /// Copies the file to the cache directory and returns the cache path.
  Future<String?> cacheThumbnailFromFile(
    String stableIdentifier,
    String sourceFilePath,
  ) async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return null;
    }

    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return null;

      final cacheKey = _generateCacheKey(stableIdentifier);
      final cachedFile = File('${_cacheDirectory!.path}/$cacheKey.png');
      
      // Copy the file to cache
      await sourceFile.copy(cachedFile.path);
      return cachedFile.path;
    } catch (e) {
      // If caching fails, return null
      return null;
    }
  }

  /// Clears all cached thumbnails.
  ///
  /// Useful for freeing up disk space or forcing regeneration.
  Future<void> clearCache() async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return;
    }

    try {
      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      // Ignore errors during cache clearing
    }
  }

  /// Gets the total size of the cache directory in bytes.
  Future<int> getCacheSize() async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return 0;
    }

    try {
      if (!await _cacheDirectory!.exists()) return 0;

      int totalSize = 0;
      await for (final entity in _cacheDirectory!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Cleans up old cache entries that haven't been accessed recently.
  ///
  /// This is a simple implementation - in production, you might want to
  /// track access times and remove entries older than a certain threshold.
  Future<void> cleanupOldCache({Duration maxAge = const Duration(days: 30)}) async {
    if (!_initialized || _cacheDirectory == null) {
      await initialize();
      if (_cacheDirectory == null) return;
    }

    try {
      if (!await _cacheDirectory!.exists()) return;

      final now = DateTime.now();
      await for (final entity in _cacheDirectory!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          if (age > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}

