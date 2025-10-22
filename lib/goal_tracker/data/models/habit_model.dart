import 'package:hive/hive.dart';
import '../../domain/entities/habit.dart';

part 'habit_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// HabitModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Habit` entity within Hive.
/// - Linked to a `Milestone` through `milestoneId` and to a `Goal` through
///   `goalId`, maintaining relational integrity.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// Nullable fields:
/// - `description` and `targetCompletions` may be null.
/// - Hive will persist `null` values safely.
///
/// Developer Guidance:
/// - Keep this model structural; do not add domain logic.
/// - Update conversion methods (`fromEntity` / `toEntity`) when domain changes.
/// - `typeId: 3` must be unique across all Hive models.
///   (Goal=0, Milestone=1, Task=2, Habit=3)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 3)
class HabitModel extends HiveObject {
  /// Unique identifier for the habit.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Human-readable habit title.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String name;

  /// Optional habit description or notes.
  ///
  /// Hive field number **2** — nullable.
  @HiveField(2)
  String? description;

  /// Reference to the parent Milestone this habit belongs to.
  ///
  /// Hive field number **3** — required; stores the Milestone's unique ID.
  @HiveField(3)
  String milestoneId;

  /// Reference to the parent Goal this habit is associated with.
  ///
  /// This is derived from the milestone's goalId and should be auto-set
  /// during create/update operations. The UI should not allow direct editing.
  /// Hive field number **4** — required; stores the Goal's unique ID.
  @HiveField(4)
  String goalId;

  /// Recurrence rule defining when the habit should be performed.
  ///
  /// Follows RFC 5545 RRULE format. Examples:
  /// - "FREQ=DAILY" (every day)
  /// - "FREQ=WEEKLY;BYDAY=MO,WE,FR" (Monday, Wednesday, Friday)
  /// - "FREQ=DAILY;INTERVAL=2" (every 2 days)
  /// Hive field number **5** — required.
  @HiveField(5)
  String rrule;

  /// Optional weight for milestone contribution.
  ///
  /// When a habit is completed, it contributes this many units to the
  /// milestone's actualValue. If null, defaults to 1.
  /// Hive field number **6** — nullable.
  @HiveField(6)
  int? targetCompletions;

  /// Whether the habit is currently active.
  ///
  /// Inactive habits are preserved but don't appear in default lists
  /// and don't contribute to milestone progress.
  /// Hive field number **7** — defaults to true for backward compatibility.
  @HiveField(7)
  bool isActive;

  HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.milestoneId,
    required this.goalId,
    required this.rrule,
    this.targetCompletions,
    this.isActive = true,
  });

  /// Factory constructor to build a [HabitModel] from a domain [Habit].
  factory HabitModel.fromEntity(Habit h) => HabitModel(
        id: h.id,
        name: h.name,
        description: h.description,
        milestoneId: h.milestoneId,
        goalId: h.goalId,
        rrule: h.rrule,
        targetCompletions: h.targetCompletions,
        isActive: h.isActive,
      );

  /// Converts this model back into a domain [Habit] entity.
  Habit toEntity() => Habit(
        id: id,
        name: name,
        description: description,
        milestoneId: milestoneId,
        goalId: goalId,
        rrule: rrule,
        targetCompletions: targetCompletions,
        isActive: isActive,
      );

  /// Creates a copy of this HabitModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? milestoneId,
    String? goalId,
    String? rrule,
    int? targetCompletions,
    bool? isActive,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      milestoneId: milestoneId ?? this.milestoneId,
      goalId: goalId ?? this.goalId,
      rrule: rrule ?? this.rrule,
      targetCompletions: targetCompletions ?? this.targetCompletions,
      isActive: isActive ?? this.isActive,
    );
  }
}
