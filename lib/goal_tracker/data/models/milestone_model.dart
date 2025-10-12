import 'package:hive/hive.dart';
import '../../domain/entities/milestone.dart';

part 'milestone_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// MilestoneModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Milestone` entity within Hive.
/// - Linked to a `Goal` through `goalId`, maintaining relational integrity.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// Nullable fields:
/// - `description`, `plannedValue`, `actualValue`, and `targetDate` may be null.
/// - Hive will persist `null` values safely.
///
/// Developer Guidance:
/// - Keep this model structural; do not add domain logic.
/// - Update conversion methods (`fromEntity` / `toEntity`) when domain changes.
/// - `typeId: 1` must be unique across all Hive models.
/// ---------------------------------------------------------------------------

@HiveType(typeId: 1)
class MilestoneModel extends HiveObject {
  /// Unique identifier for the milestone.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Human-readable milestone title.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String name;

  /// Optional milestone description or notes.
  ///
  /// Hive field number **2** — nullable.
  @HiveField(2)
  String? description;

  /// Planned numeric value (e.g., target quantity, expected metric).
  ///
  /// Hive field number **3** — nullable.
  @HiveField(3)
  double? plannedValue;

  /// Actual achieved numeric value.
  ///
  /// Hive field number **4** — nullable.
  @HiveField(4)
  double? actualValue;

  /// Expected target date for milestone completion.
  ///
  /// Hive field number **5** — nullable; stored as ISO timestamp.
  @HiveField(5)
  DateTime? targetDate;

  /// Reference to the parent Goal this milestone belongs to.
  ///
  /// Hive field number **6** — required; stores the Goal’s unique ID.
  @HiveField(6)
  String goalId;

  MilestoneModel({
    required this.id,
    required this.name,
    this.description,
    this.plannedValue,
    this.actualValue,
    this.targetDate,
    required this.goalId,
  });

  /// Factory constructor to build a [MilestoneModel] from a domain [Milestone].
  factory MilestoneModel.fromEntity(Milestone m) => MilestoneModel(
        id: m.id,
        name: m.name,
        description: m.description,
        plannedValue: m.plannedValue,
        actualValue: m.actualValue,
        targetDate: m.targetDate,
        goalId: m.goalId,
      );

  /// Converts this model back into a domain [Milestone] entity.
  Milestone toEntity() => Milestone(
        id: id,
        name: name,
        description: description,
        plannedValue: plannedValue,
        actualValue: actualValue,
        targetDate: targetDate,
        goalId: goalId,
      );
}
