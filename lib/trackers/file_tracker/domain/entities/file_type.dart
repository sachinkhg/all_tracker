/// Enum representing the type of a file.
enum FileType {
  image,
  video,
  other,
}

extension FileTypeExtension on FileType {
  /// Returns true if this is an image type.
  bool get isImage => this == FileType.image;

  /// Returns true if this is a video type.
  bool get isVideo => this == FileType.video;

  /// Returns true if this is neither image nor video.
  bool get isOther => this == FileType.other;
}

/// Helper class for FileType operations.
class FileTypeHelper {
  /// Determines file type from file extension.
  static FileType fromExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'ico',
      'tiff',
      'tif',
    ];
    const videoExtensions = [
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
      'wmv',
      'm4v',
      '3gp',
      'ogv',
    ];

    if (imageExtensions.contains(extension)) {
      return FileType.image;
    } else if (videoExtensions.contains(extension)) {
      return FileType.video;
    } else {
      return FileType.other;
    }
  }
}

