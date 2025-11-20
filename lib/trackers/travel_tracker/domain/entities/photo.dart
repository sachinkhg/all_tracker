import 'package:equatable/equatable.dart';

/// Domain model for a Photo.
///
/// Represents a photo associated with a journal entry.
/// Actual image files are stored in device storage, this entity stores metadata and file path.
class Photo extends Equatable {
  /// Unique identifier for the photo (GUID recommended).
  final String id;

  /// Associated journal entry ID.
  final String journalEntryId;

  /// File path to the photo on device storage.
  final String filePath;

  /// Optional caption for the photo.
  final String? caption;

  /// Date when the photo was taken.
  final DateTime? dateTaken;

  /// Optional day tag for filtering by day.
  final DateTime? taggedDay;

  /// Optional location tag.
  final String? taggedLocation;

  /// When the photo record was created.
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.journalEntryId,
    required this.filePath,
    this.caption,
    this.dateTaken,
    this.taggedDay,
    this.taggedLocation,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        journalEntryId,
        filePath,
        caption,
        dateTaken,
        taggedDay,
        taggedLocation,
        createdAt,
      ];
}

