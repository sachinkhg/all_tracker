import 'package:hive/hive.dart';
import '../../domain/entities/habit_completion.dart';

part 'habit_completion_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// HabitCompletionModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `HabitCompletion` entity within Hive.
/// - Linked to a `Habit` through `habitId`, maintaining relational integrity.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// Nullable fields:
/// - `note` may be null.
/// - Hive will persist `null` values safely.
///
/// Developer Guidance:
/// - Keep this model structural; do not add domain logic.
/// - Update conversion methods (`fromEntity` / `toEntity`) when domain changes.
/// - `typeId: 4` must be unique across all Hive models.
///   (Goal=0, Milestone=1, Task=2, Habit=3, HabitCompletion=4)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 4)
class HabitCompletionModel extends HiveObject {
  /// Unique identifier for the completion.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Reference to the parent Habit this completion belongs to.
  ///
  /// Hive field number **1** — required; stores the Habit's unique ID.
  @HiveField(1)
  String habitId;

  /// Date when the habit was completed.
  ///
  /// Should be normalized to date-only (midnight UTC) to avoid timezone issues.
  /// Hive field number **2** — required; stored as ISO timestamp.
  @HiveField(2)
  DateTime completionDate;

  /// Optional note about the completion.
  ///
  /// Hive field number **3** — nullable.
  @HiveField(3)
  String? note;

  HabitCompletionModel({
    required this.id,
    required this.habitId,
    required this.completionDate,
    this.note,
  });

  /// Factory constructor to build a [HabitCompletionModel] from a domain [HabitCompletion].
  factory HabitCompletionModel.fromEntity(HabitCompletion hc) => HabitCompletionModel(
        id: hc.id,
        habitId: hc.habitId,
        completionDate: hc.completionDate,
        note: hc.note,
      );

  /// Converts this model back into a domain [HabitCompletion] entity.
  HabitCompletion toEntity() => HabitCompletion(
        id: id,
        habitId: habitId,
        completionDate: completionDate,
        note: note,
      );

  /// Creates a copy of this HabitCompletionModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  HabitCompletionModel copyWith({
    String? id,
    String? habitId,
    DateTime? completionDate,
    String? note,
  }) {
    return HabitCompletionModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completionDate: completionDate ?? this.completionDate,
      note: note ?? this.note,
    );
  }
}
