import 'package:equatable/equatable.dart';

/// Domain entity representing metadata for a file.
///
/// This metadata (tags, notes, etc.) is stored separately from the file itself
/// and is keyed by a stable identifier (folder + name) rather than URL,
/// allowing it to persist even when the server URL changes.
class FileMetadata extends Equatable {
  /// Stable identifier for the file (folder + name).
  /// This remains constant even when the server URL changes.
  final String stableIdentifier;

  /// List of tags associated with this file.
  final List<String> tags;

  /// Optional notes/description for this file.
  final String? notes;

  /// List of cast members/people in this file (for videos/images).
  final List<String> cast;

  /// View mode: "portrait" or "landscape" (null if unknown).
  final String? viewMode;

  /// Timestamp when this metadata was last updated.
  final DateTime lastUpdated;

  const FileMetadata({
    required this.stableIdentifier,
    this.tags = const [],
    this.notes,
    this.cast = const [],
    this.viewMode,
    required this.lastUpdated,
  });

  /// Creates a copy of this metadata with the given fields replaced.
  FileMetadata copyWith({
    String? stableIdentifier,
    List<String>? tags,
    String? notes,
    List<String>? cast,
    String? viewMode,
    DateTime? lastUpdated,
  }) {
    return FileMetadata(
      stableIdentifier: stableIdentifier ?? this.stableIdentifier,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      cast: cast ?? this.cast,
      viewMode: viewMode ?? this.viewMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Returns true if this metadata has any tags.
  bool get hasTags => tags.isNotEmpty;

  /// Returns true if this metadata has notes.
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Returns true if this metadata has cast members.
  bool get hasCast => cast.isNotEmpty;

  @override
  List<Object?> get props => [
        stableIdentifier,
        tags,
        notes,
        cast,
        viewMode,
        lastUpdated,
      ];
}

