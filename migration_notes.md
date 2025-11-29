# Migration Notes — Hive Schema & TypeIds

This document serves as the single source of truth for all Hive TypeIds and schema changes in the `all_tracker` application. Maintaining strict TypeId discipline prevents data corruption and ensures backward compatibility.

---

## 📋 TypeId Registry

| TypeId | Model Class    | Box Name          | Status    | Date Added | Notes                                      |
|--------|----------------|-------------------|-----------|------------|--------------------------------------------|
| **0**  | GoalModel      | `goals_box`       | Active    | Initial    | Core goal entity                           |
| **1**  | MilestoneModel | `milestones_box`  | Active    | Initial    | Milestone entity linked to Goal            |
| **2**  | TaskModel      | `tasks_box`       | Active    | 2025-10-12 | Task entity linked to Milestone and Goal   |
| **3**  | HabitModel     | `habits_box`      | Active    | 2025-01-27 | Habit entity linked to Milestone and Goal  |
| **4**  | HabitCompletionModel | `habit_completions_box` | Active | 2025-01-27 | Habit completion tracking entity |
| **5**  | BackupMetadataModel | `backup_metadata_box` | Active | 2025-10-27 | Cloud backup metadata tracking |
| **14** | TripModel | `trips_box` | Active | 2025-01-27 | Travel trip entity |

---

## 📦 Box Registry

| Box Name                    | Purpose                           | Data Type | Status    | Notes                                      |
|-----------------------------|-----------------------------------|-----------|-----------|--------------------------------------------|
| `goals_box`                 | Goal entities                     | GoalModel | Active    | Core goal storage                           |
| `milestones_box`            | Milestone entities                | MilestoneModel | Active | Milestone storage linked to goals          |
| `tasks_box`                 | Task entities                     | TaskModel | Active    | Task storage linked to milestones          |
| `habits_box`                | Habit entities                    | HabitModel | Active    | Habit storage linked to milestones         |
| `habit_completions_box`     | Habit completion entities         | HabitCompletionModel | Active | Habit completion tracking storage |
| `backup_metadata_box`       | Backup metadata tracking          | BackupMetadataModel  | Active | Cloud backup metadata storage             |
| `view_preferences_box`      | User view field preferences       | String    | Active    | UI customization settings                  |
| `filter_preferences_box`    | User filter preferences           | String    | Active    | Filter state persistence                   |
| `sort_preferences_box`      | User sort preferences             | String    | Active    | Sort state persistence                     |

---

## 🛡️ TypeId Assignment Rules

1. **Never reuse TypeIds** — Once assigned, a TypeId is permanent for that model type.
2. **Sequential assignment** — Assign TypeIds sequentially starting from 0.
3. **Document immediately** — Add new TypeIds to this file before committing code.
4. **Reserve ranges** — Consider reserving ranges for different modules if needed.
5. **Validate uniqueness** — Always check existing TypeIds before assignment.
6. **Update constants** — Add box name constants to `lib/goal_tracker/core/constants.dart`.

---

## 🔧 Box Management Rules

1. **Stable box names** — Never change box names after release to avoid data loss.
2. **Consistent naming** — Use `snake_case` format: `entity_type_box`.
3. **Document purpose** — Each box must have a clear purpose documented here.
4. **Version compatibility** — Box names must remain stable across app versions.
5. **Cleanup unused** — Remove references to deprecated boxes in code.

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

## 📦 Model: HabitModel (TypeId: 3)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name        | Type     | Nullable | Default | Notes                                           |
|--------------|-------------------|----------|----------|---------|-------------------------------------------------|
| 0            | `id`              | String   | No       | -       | Unique identifier (GUID)                        |
| 1            | `name`            | String   | No       | -       | Habit title                                     |
| 2            | `description`     | String   | Yes      | null    | Optional description                             |
| 3            | `milestoneId`     | String   | No       | -       | Foreign key to parent Milestone                 |
| 4            | `goalId`          | String   | No       | -       | Foreign key to parent Goal (auto-assigned from Milestone) |
| 5            | `rrule`           | String   | No       | -       | Recurrence rule (RFC 5545 RRULE format)         |
| 6            | `targetCompletions` | int    | Yes      | null    | Optional weight for milestone contribution       |
| 7            | `isActive`        | bool     | No       | true    | Whether habit is currently active               |

**Business Rules:**
- `goalId` is **auto-assigned** from the associated Milestone's `goalId` during create/update operations.
- UI must **not** allow direct editing of `goalId`.
- When a Milestone is selected, the UI displays the associated Goal name as read-only.
- HabitCubit enforces this rule by fetching the Milestone before persisting the Habit.
- `rrule` must follow RFC 5545 RRULE format for recurrence rules.
- `targetCompletions` defaults to 1 if null when calculating milestone progress.

**Migration History:**
- v1.0 (2025-01-27): Initial schema with 8 fields.

---

## 📦 Model: HabitCompletionModel (TypeId: 4)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name      | Type     | Nullable | Default | Notes                                           |
|--------------|-----------------|----------|----------|---------|-------------------------------------------------|
| 0            | `id`            | String   | No       | -       | Unique identifier (GUID)                        |
| 1            | `habitId`       | String   | No       | -       | Foreign key to parent Habit                     |
| 2            | `completionDate`| DateTime | No       | -       | Date when habit was completed (normalized to date-only) |
| 3            | `note`          | String   | Yes      | null    | Optional completion note                         |

**Business Rules:**
- `completionDate` is normalized to date-only (midnight UTC) to avoid timezone issues.
- Each completion increments the associated milestone's `actualValue` by the habit's `targetCompletions` (or 1 if null).
- Deleting a completion decrements the milestone's `actualValue` by the same amount.
- The milestone progress update is handled atomically in the `ToggleCompletionForDate` use case.

**Migration History:**
- v1.0 (2025-01-27): Initial schema with 4 fields.

---

## 📦 Model: TripModel (TypeId: 14)

### Schema Version: 2.0 (Current)

**Fields:**

| Field Number | Field Name              | Type     | Nullable | Default | Notes                                           |
|--------------|-------------------------|----------|----------|---------|-------------------------------------------------|
| 0            | `id`                    | String   | No       | -       | Unique identifier (GUID)                        |
| 1            | `title`                 | String   | No       | -       | Trip title                                      |
| 2            | `destination`           | String   | Yes      | null    | Destination location name/address               |
| 3            | `startDate`             | DateTime | Yes      | null    | Trip start date                                 |
| 4            | `endDate`               | DateTime | Yes      | null    | Trip end date                                   |
| 5            | `description`           | String   | Yes      | null    | Optional description                             |
| 6            | `createdAt`             | DateTime | No       | -       | Creation timestamp                              |
| 7            | `updatedAt`             | DateTime | No       | -       | Last update timestamp                           |
| 8            | `tripTypeIndex`         | int      | Yes      | null    | Trip type enum index (work=0, leisure=1)        |
| 9            | `destinationLatitude`   | double   | Yes      | null    | Destination latitude coordinate                 |
| 10           | `destinationLongitude`  | double   | Yes      | null    | Destination longitude coordinate                |
| 11           | `destinationMapLink`    | String   | Yes      | null    | Map link (Google Maps or Apple Maps URL)        |

**Migration History:**
- v1.0 (Initial): Fields 0-7 defined (id, title, destination, startDate, endDate, description, createdAt, updatedAt).
- v2.0 (2025-01-27): Added fields 8-11 (tripTypeIndex, destinationLatitude, destinationLongitude, destinationMapLink) for trip type classification and enhanced destination location support.

**Notes:**
- `tripTypeIndex` stores the TripType enum as an integer (0=work, 1=leisure). Nullable for backward compatibility.
- Destination location can be specified via string (`destination`), coordinates (`destinationLatitude`/`destinationLongitude`), or map link (`destinationMapLink`).
- All new fields (8-11) are nullable to ensure backward compatibility with existing trip data.

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
8. **Update tests** to cover the new field.

### Removing a Field

1. **Do NOT reuse the field number** — leave it marked as "deprecated" in this file.
2. **Update the model class** to remove the field.
3. **Update converters** to ignore the deprecated field during deserialization.
4. **Document** the removal and the deprecated field number.
5. **Update tests** to remove references to the deprecated field.

### Creating a New Model

1. **Assign the next available TypeId** (check the TypeId Registry table above).
2. **Create the model class** with `@HiveType(typeId: X)` annotation.
3. **Define all fields** with `@HiveField(N)` annotations (start from 0).
4. **Add box name constant** to `lib/goal_tracker/core/constants.dart`.
5. **Register the adapter** in `core/hive_initializer.dart`.
6. **Open the box** in `core/hive_initializer.dart`.
7. **Wire up DI** in `goal_tracker/core/injection.dart`.
8. **Document the new model** in this file with a new section.
9. **Run code generator**: `flutter packages pub run build_runner build --delete-conflicting-outputs`
10. **Create comprehensive tests** for the new model.

### Creating a New Preference Box

1. **Add box name constant** to `lib/goal_tracker/core/constants.dart`.
2. **Open the box** in `core/hive_initializer.dart`.
3. **Create preference service** in `lib/goal_tracker/core/`.
4. **Wire up service** in `goal_tracker/core/injection.dart`.
5. **Document the new box** in this file.
6. **Test** preference persistence and retrieval.

---

## 🧪 Testing Migrations

When making schema changes:

1. **Backup test data** before running migrations.
2. **Create unit tests** that verify old data can be read with the new schema.
3. **Test edge cases**: null values, missing fields, default values.
4. **Document breaking changes** and provide migration scripts if needed.
5. **Test data integrity** after migration.
6. **Verify performance** with large datasets.
7. **Test rollback scenarios** if possible.

### Migration Test Checklist

- [ ] **Data Preservation**: All existing data is preserved
- [ ] **New Fields**: New fields work with default values
- [ ] **Nullable Fields**: Nullable fields handle null correctly
- [ ] **Type Safety**: No type conversion errors
- [ ] **Performance**: Migration completes in reasonable time
- [ ] **Error Handling**: Graceful handling of corrupted data
- [ ] **Rollback**: Can revert if needed (if applicable)

---

## 🚨 Error Handling & Recovery

### Common Migration Errors

1. **TypeId Conflicts**: Multiple models using same TypeId
   - **Solution**: Check TypeId Registry, assign unique ID
   - **Prevention**: Always validate TypeId before assignment

2. **Field Number Conflicts**: Reusing field numbers
   - **Solution**: Use next available field number
   - **Prevention**: Document all field numbers in this file

3. **Box Corruption**: Hive box becomes unreadable
   - **Solution**: Implement recovery logic in `HiveInitializer`
   - **Prevention**: Regular data validation and backups

4. **Schema Incompatibility**: Old data incompatible with new schema
   - **Solution**: Implement migration logic in model converters
   - **Prevention**: Always make additive changes when possible

### Recovery Procedures

```dart
// Example: Box corruption recovery
try {
  var box = await Hive.openBox<GoalModel>('goals_box');
} on HiveError catch (e) {
  if (e.message.contains('corrupted')) {
    // Backup corrupted data
    await _backupCorruptedData('goals_box');
    // Delete and recreate box
    await Hive.deleteBoxFromDisk('goals_box');
    var box = await Hive.openBox<GoalModel>('goals_box');
  }
}
```

---

## 📚 References

- [Hive Documentation](https://docs.hivedb.dev/)
- [Hive TypeAdapter Guide](https://docs.hivedb.dev/#/custom-objects/type_adapters)
- [Hive Migration Guide](https://docs.hivedb.dev/#/advanced/migrations)
- Project Architecture: `ARCHITECTURE.md`
- New Model Checklist: `readme/new_model_checklist.md`
- Constants File: `lib/goal_tracker/core/constants.dart`
- Hive Initializer: `lib/core/hive_initializer.dart`

---

## 📋 Quick Reference

### Current TypeIds
- **0**: GoalModel
- **1**: MilestoneModel  
- **2**: TaskModel
- **3**: HabitModel
- **4**: HabitCompletionModel
- **5**: BackupMetadataModel
- **14**: TripModel
- **Next Available**: 6 (Note: TypeIds 6-13 may be used by other modules)

### Current Box Names
- `goals_box` - Goal entities
- `milestones_box` - Milestone entities
- `tasks_box` - Task entities
- `habits_box` - Habit entities
- `habit_completions_box` - Habit completion entities
- `view_preferences_box` - UI preferences
- `filter_preferences_box` - Filter preferences
- `sort_preferences_box` - Sort preferences

### Key Files to Update
1. `migration_notes.md` - This file (TypeId and schema documentation)
2. `lib/goal_tracker/core/constants.dart` - Box name constants
3. `lib/core/hive_initializer.dart` - Adapter registration and box opening
4. `lib/goal_tracker/core/injection.dart` - Dependency injection wiring

---

**Last Updated:** 2025-01-27  
**Version:** 2.1  
**Maintained by:** Development Team  
**Review Frequency:** On every schema change  
**Next Review:** On next model addition

