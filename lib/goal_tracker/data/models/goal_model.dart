import 'package:hive/hive.dart';
import '../../domain/entities/goal.dart';

part 'goal_model.g.dart'; // Build_runner will generate this file

/// ---------------------------------------------------------------------------
/// GoalModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Acts as the persistent representation of a `Goal` entity within Hive.
/// - Bridges the data and domain layers — stores normalized data and converts
///   to/from the domain-level `Goal` entity.
///
/// Serialization & Compatibility Rules:
/// - Each `@HiveField` annotation defines a serialized field index.
///   * **Do not reuse or renumber fields** — once written, numbers become part
///     of the persisted schema.
///   * When adding/removing fields, document the change in `migration_notes.md`
///     and create migration logic if backward compatibility is needed.
/// - Nullable fields (`description`, `targetDate`, `context`) indicate optional
///   data — Hive stores `null` when not provided.
/// - Default values (e.g., `isCompleted = false`) ensure predictable deserialization
///   when older versions lack the field.
///
/// Developer guidance:
/// - Keep `GoalModel` purely structural — avoid domain/business logic.
/// - If the domain model changes, adjust conversion methods (`fromEntity`/`toEntity`)
///   rather than adding behavior here.
/// - Versioning: When extending this class, incrementally add new fields with
///   unique field numbers; never modify existing numbers or change types in place.
///
/// Hive integration:
/// - `typeId: 0` uniquely identifies this adapter. Update `migration_notes.md` if
///   a new adapter or model type is introduced.
/// ---------------------------------------------------------------------------

@HiveType(typeId: 0)
class GoalModel extends HiveObject {
  /// Unique identifier for the goal.
  /// 
  /// Hive field number **0** — stable ID, must never change or be reused.
  @HiveField(0)
  String id;

  /// Human-readable goal title.
  ///
  /// Hive field number **1** — required, always non-null.
  @HiveField(1)
  String name;

  /// Optional description providing context or details.
  ///
  /// Hive field number **2** — nullable; stored as `null` if not provided.
  @HiveField(2)
  String? description;

  /// Optional target date for completion or tracking.
  ///
  /// Hive field number **3** — nullable; stored as ISO timestamp internally.
  @HiveField(3)
  DateTime? targetDate;

  /// Context or category label (e.g., Work, Personal, Health).
  ///
  /// Hive field number **4** — nullable; string token, references constants list.
  @HiveField(4)
  String? context;

  /// Whether the goal has been marked as completed.
  ///
  /// Hive field number **5** — default is `false` for backward compatibility with
  /// older data that might not include this field.
  @HiveField(5)
  bool isCompleted = false;

  GoalModel({
    required this.id,
    required this.name,
    this.description,
    this.targetDate,
    this.context,
    this.isCompleted = false,
  });

  /// Factory constructor to build a [GoalModel] from a domain [Goal] entity.
  ///
  /// - Use this when persisting domain entities into Hive.
  /// - Handles nullable fields gracefully to ensure serialization safety.
  /// - If older entities lack new fields, default values are applied automatically.
  factory GoalModel.fromEntity(Goal g) => GoalModel(
        id: g.id,
        name: g.name,
        description: g.description,
        targetDate: g.targetDate,
        context: g.context,
        isCompleted: g.isCompleted,
      );

  /// Converts this Hive model back into a domain [Goal] entity.
  ///
  /// - Use this in repositories when reading from Hive before returning to the domain layer.
  /// - Avoid embedding Hive-specific logic or transformations here; domain should remain storage-agnostic.
  Goal toEntity() => Goal(
        id: id,
        name: name,
        description: description,
        targetDate: targetDate,
        context: context,
        isCompleted: isCompleted,
      );
}
