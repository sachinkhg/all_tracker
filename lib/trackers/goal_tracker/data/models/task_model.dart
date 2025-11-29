import 'package:hive/hive.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// TaskModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Task` entity within Hive.
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
/// - `targetDate` may be null.
/// - `milestoneId` and `goalId` are nullable (changed from non-nullable to support standalone tasks).
///   This change was made to support tasks that are not linked to milestones/goals.
/// - Hive will persist `null` values safely.
/// 
/// Migration note:
/// - When `milestoneId` and `goalId` were changed from non-nullable to nullable,
///   existing data in Hive boxes remains compatible. The adapter automatically handles
///   reading both old (non-null) and new (nullable) values.
///
/// Developer Guidance:
/// - Keep this model structural; do not add domain logic.
/// - Update conversion methods (`fromEntity` / `toEntity`) when domain changes.
/// - `typeId: 2` must be unique across all Hive models.
///   (Goal=0, Milestone=1, Task=2)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 2)
class TaskModel extends HiveObject {
  /// Unique identifier for the task.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Human-readable task title.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String name;

  /// Expected target date for task completion.
  ///
  /// Hive field number **2** — nullable; stored as ISO timestamp.
  @HiveField(2)
  DateTime? targetDate;

  /// Reference to the parent Milestone this task belongs to.
  ///
  /// Hive field number **3** — nullable; stores the Milestone's unique ID.
  /// Null for standalone tasks not linked to a milestone.
  @HiveField(3)
  String? milestoneId;

  /// Reference to the parent Goal this task is associated with.
  ///
  /// This is derived from the milestone's goalId and should be auto-set
  /// during create/update operations. The UI should not allow direct editing.
  /// Hive field number **4** — nullable; stores the Goal's unique ID.
  /// Null for standalone tasks not linked to a goal/milestone.
  @HiveField(4)
  String? goalId;

  /// Current status of the task.
  ///
  /// Valid values: 'To Do', 'In Progress', 'Complete'.
  /// Hive field number **5** — defaults to 'To Do' for backward compatibility.
  @HiveField(5)
  String status;

  TaskModel({
    required this.id,
    required this.name,
    this.targetDate,
    this.milestoneId,
    this.goalId,
    this.status = 'To Do',
  });

  /// Factory constructor to build a [TaskModel] from a domain [Task].
  factory TaskModel.fromEntity(Task t) => TaskModel(
        id: t.id,
        name: t.name,
        targetDate: t.targetDate,
        milestoneId: t.milestoneId,
        goalId: t.goalId,
        status: t.status,
      );

  /// Converts this model back into a domain [Task] entity.
  Task toEntity() => Task(
        id: id,
        name: name,
        targetDate: targetDate,
        milestoneId: milestoneId,
        goalId: goalId,
        status: status,
      );

  /// Creates a copy of this TaskModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  TaskModel copyWith({
    String? id,
    String? name,
    DateTime? targetDate,
    String? milestoneId,
    String? goalId,
    String? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDate: targetDate ?? this.targetDate,
      milestoneId: milestoneId ?? this.milestoneId,
      goalId: goalId ?? this.goalId,
      status: status ?? this.status,
    );
  }
}

