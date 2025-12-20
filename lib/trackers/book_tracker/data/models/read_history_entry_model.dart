import 'package:hive/hive.dart';
import '../../domain/entities/read_history_entry.dart';

part 'read_history_entry_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// ReadHistoryEntryModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted [ReadHistoryEntry] entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 33 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 33)
class ReadHistoryEntryModel extends HiveObject {
  /// Date when the reading cycle started.
  ///
  /// Hive field number **0** — nullable.
  @HiveField(0)
  DateTime? dateStarted;

  /// Date when the reading cycle was completed.
  ///
  /// Hive field number **1** — nullable.
  @HiveField(1)
  DateTime? dateRead;

  ReadHistoryEntryModel({
    this.dateStarted,
    this.dateRead,
  });

  /// Factory constructor to build a [ReadHistoryEntryModel] from a domain [ReadHistoryEntry].
  factory ReadHistoryEntryModel.fromEntity(ReadHistoryEntry entry) =>
      ReadHistoryEntryModel(
        dateStarted: entry.dateStarted,
        dateRead: entry.dateRead,
      );

  /// Converts this model back into a domain [ReadHistoryEntry] entity.
  ReadHistoryEntry toEntity() {
    return ReadHistoryEntry(
      dateStarted: dateStarted,
      dateRead: dateRead,
    );
  }

  /// Creates a copy of this ReadHistoryEntryModel with the given fields replaced.
  ReadHistoryEntryModel copyWith({
    DateTime? dateStarted,
    DateTime? dateRead,
  }) {
    return ReadHistoryEntryModel(
      dateStarted: dateStarted ?? this.dateStarted,
      dateRead: dateRead ?? this.dateRead,
    );
  }
}

