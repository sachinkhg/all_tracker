# Migration Notes — Hive Schema & TypeIds

This document serves as the single source of truth for all Hive TypeIds and schema changes in the `all_tracker` application. Maintaining strict TypeId discipline prevents data corruption and ensures backward compatibility.

---

## 📋 TypeId Registry

| TypeId | Model Class    | Box Name          | Status    | Date Added | Notes                                      |
|--------|----------------|-------------------|-----------|------------|--------------------------------------------|
| **0**  | GoalModel      | `goals_box`       | Active    | Initial    | Core goal entity                           |
| **1**  | MilestoneModel | `milestones_box`  | Active    | Initial    | Milestone entity linked to Goal            |
| **2**  | TaskModel      | `tasks_box`       | Active    | 2025-10-12 | Task entity linked to Milestone and Goal   |

---

## 🛡️ TypeId Assignment Rules

1. **Never reuse TypeIds** — Once assigned, a TypeId is permanent for that model type.
2. **Sequential assignment** — Assign TypeIds sequentially starting from 0.
3. **Document immediately** — Add new TypeIds to this file before committing code.
4. **Reserve ranges** — Consider reserving ranges for different modules if needed.

---

## 📦 Model: GoalModel (TypeId: 0)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name    | Type        | Nullable | Default | Notes                           |
|--------------|---------------|-------------|----------|---------|---------------------------------|
| 0            | `id`          | String      | No       | -       | Unique identifier (GUID)        |
| 1            | `name`        | String      | No       | -       | Goal title                      |
| 2            | `description` | String      | Yes      | null    | Optional description            |
| 3            | `targetDate`  | DateTime    | Yes      | null    | Optional target date            |
| 4            | `context`     | String      | Yes      | null    | Category (Work, Personal, etc.) |
| 5            | `isCompleted` | bool        | No       | false   | Completion status               |

**Migration History:**
- v1.0 (Initial): All fields defined.

---

## 📦 Model: MilestoneModel (TypeId: 1)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name      | Type     | Nullable | Default | Notes                              |
|--------------|-----------------|----------|----------|---------|------------------------------------|
| 0            | `id`            | String   | No       | -       | Unique identifier (GUID)           |
| 1            | `name`          | String   | No       | -       | Milestone title                    |
| 2            | `description`   | String   | Yes      | null    | Optional description               |
| 3            | `plannedValue`  | double   | Yes      | null    | Target quantitative value          |
| 4            | `actualValue`   | double   | Yes      | null    | Achieved quantitative value        |
| 5            | `targetDate`    | DateTime | Yes      | null    | Expected completion date           |
| 6            | `goalId`        | String   | No       | -       | Foreign key to parent Goal         |

**Migration History:**
- v1.0 (Initial): All fields defined.

---

## 📦 Model: TaskModel (TypeId: 2)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name    | Type     | Nullable | Default   | Notes                                           |
|--------------|---------------|----------|----------|-----------|-------------------------------------------------|
| 0            | `id`          | String   | No       | -         | Unique identifier (GUID)                        |
| 1            | `name`        | String   | No       | -         | Task title                                      |
| 2            | `targetDate`  | DateTime | Yes      | null      | Expected completion date                        |
| 3            | `milestoneId` | String   | No       | -         | Foreign key to parent Milestone                 |
| 4            | `goalId`      | String   | No       | -         | Foreign key to parent Goal (derived from Milestone) |
| 5            | `status`      | String   | No       | "To Do"   | Task status: "To Do", "In Progress", "Complete" |

**Business Rules:**
- `goalId` is **auto-assigned** from the associated Milestone's `goalId` during create/update operations.
- UI must **not** allow direct editing of `goalId`.
- When a Milestone is selected, the UI displays the associated Goal name as read-only.
- TaskCubit enforces this rule by fetching the Milestone before persisting the Task.

**Migration History:**
- v1.0 (2025-10-12): Initial schema with 6 fields.

---

## 🔄 Migration Procedures

### Adding a New Field to an Existing Model

1. **Assign a new field number** (never reuse old numbers).
2. **Make the field nullable** or provide a **default value** for backward compatibility.
3. **Update the model class** with `@HiveField(N)` annotation.
4. **Update converters** (`fromEntity`, `toEntity`, `copyWith`).
5. **Run code generator**: `flutter packages pub run build_runner build --delete-conflicting-outputs`
6. **Document the change** in this file under the model's "Migration History" section.
7. **Test** with existing data to ensure no corruption.

### Removing a Field

1. **Do NOT reuse the field number** — leave it marked as "deprecated" in this file.
2. **Update the model class** to remove the field.
3. **Update converters** to ignore the deprecated field during deserialization.
4. **Document** the removal and the deprecated field number.

### Creating a New Model

1. **Assign the next available TypeId** (check the TypeId Registry table above).
2. **Create the model class** with `@HiveType(typeId: X)` annotation.
3. **Define all fields** with `@HiveField(N)` annotations (start from 0).
4. **Register the adapter** in `core/hive_initializer.dart`.
5. **Open the box** in `core/hive_initializer.dart`.
6. **Wire up DI** in `goal_tracker/core/injection.dart`.
7. **Document the new model** in this file with a new section.
8. **Run code generator**: `flutter packages pub run build_runner build --delete-conflicting-outputs`

---

## 🧪 Testing Migrations

When making schema changes:

1. **Backup test data** before running migrations.
2. **Create unit tests** that verify old data can be read with the new schema.
3. **Test edge cases**: null values, missing fields, default values.
4. **Document breaking changes** and provide migration scripts if needed.

---

## 📚 References

- [Hive Documentation](https://docs.hivedb.dev/)
- [Hive TypeAdapter Guide](https://docs.hivedb.dev/#/custom-objects/type_adapters)
- Project Architecture: `ARCHITECTURE.md`
- New Model Checklist: `readme/new_model_checklist.md`

---

**Last Updated:** 2025-10-12  
**Maintained by:** Development Team  
**Review Frequency:** On every schema change

