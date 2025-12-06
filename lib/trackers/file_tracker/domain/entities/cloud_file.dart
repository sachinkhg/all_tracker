import 'package:equatable/equatable.dart';
import 'file_type.dart';

/// Domain entity representing a file from the cloud/server.
///
/// Contains metadata about the file including its URL, name, type,
/// size, modification date, and folder path.
class CloudFile extends Equatable {
  /// Full URL to access the file.
  final String url;

  /// Name of the file (filename with extension).
  final String name;

  /// Type of the file (image, video, or other).
  final FileType type;

  /// Size of the file in bytes (null if unknown).
  final int? size;

  /// Modification date of the file (null if unknown).
  final DateTime? modifiedDate;

  /// Folder/path where the file is located (e.g., "/photos/2024").
  final String folder;

  /// MIME type of the file (null if unknown).
  final String? mimeType;

  const CloudFile({
    required this.url,
    required this.name,
    required this.type,
    this.size,
    this.modifiedDate,
    this.folder = '',
    this.mimeType,
  });

  /// Creates a copy of this file with the given fields replaced.
  CloudFile copyWith({
    String? url,
    String? name,
    FileType? type,
    int? size,
    DateTime? modifiedDate,
    String? folder,
    String? mimeType,
  }) {
    return CloudFile(
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      folder: folder ?? this.folder,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  /// Returns true if this is an image file.
  bool get isImage => type.isImage;

  /// Returns true if this is a video file.
  bool get isVideo => type.isVideo;

  /// Returns true if this is a folder/directory.
  bool get isFolder => name.endsWith('/') || url.endsWith('/');

  /// Returns the file extension (lowercase).
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Returns a formatted file size string (e.g., "1.5 MB").
  String get formattedSize {
    if (size == null) return 'Unknown size';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    if (size! < 1024 * 1024 * 1024) {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [
        url,
        name,
        type,
        size,
        modifiedDate,
        folder,
        mimeType,
      ];
}

