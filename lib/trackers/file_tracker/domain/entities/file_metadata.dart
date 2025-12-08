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

  /// Timestamp when this metadata was last updated.
  final DateTime lastUpdated;

  const FileMetadata({
    required this.stableIdentifier,
    this.tags = const [],
    this.notes,
    required this.lastUpdated,
  });

  /// Creates a copy of this metadata with the given fields replaced.
  FileMetadata copyWith({
    String? stableIdentifier,
    List<String>? tags,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return FileMetadata(
      stableIdentifier: stableIdentifier ?? this.stableIdentifier,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Returns true if this metadata has any tags.
  bool get hasTags => tags.isNotEmpty;

  /// Returns true if this metadata has notes.
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  @override
  List<Object?> get props => [
        stableIdentifier,
        tags,
        notes,
        lastUpdated,
      ];
}

