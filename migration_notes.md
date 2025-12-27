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
| **6**  | InvestmentComponentModel | `investment_components_box` | Active | 2025-01-27 | Investment component entity |
| **7**  | IncomeCategoryModel | `income_categories_box` | Active | 2025-01-27 | Income category entity |
| **8**  | ExpenseCategoryModel | `expense_categories_box` | Active | 2025-01-27 | Expense category entity |
| **9**  | InvestmentPlanModel | `investment_plans_box` | Active | 2025-01-27 | Investment plan entity |
| **10** | IncomeEntryModel | `income_categories_box` | Active | 2025-01-27 | Income entry entity |
| **11** | ExpenseEntryModel | `expense_categories_box` | Active | 2025-01-27 | Expense entry entity |
| **12** | ComponentAllocationModel | `investment_components_box` | Active | 2025-01-27 | Component allocation entity |
| **13** | RetirementPlanModel | `retirement_plan_box` | Active | 2025-01-27 | Retirement plan entity |
| **14** | TripModel | `trips_box` | Active | 2025-01-27 | Travel trip entity |
| **15** | TripProfileModel | `trip_profiles_box` | Active | 2025-01-27 | Travel trip profile entity |
| **16** | ItineraryDayModel | `itinerary_days_box` | Active | 2025-01-27 | Itinerary day entity |
| **17** | ItineraryItemModel | `itinerary_items_box` | Active | 2025-01-27 | Itinerary item entity |
| **18** | JournalEntryModel | `journal_entries_box` | Active | 2025-01-27 | Travel journal entry entity |
| **19** | PhotoModel | `photos_box` | Active | 2025-01-27 | Travel photo entity |
| **20** | ExpenseModel | `expenses_box` | Active | 2025-01-27 | Travel expense entity |
| **21** | TravelerModel | `travelers_box` | Active | 2025-01-27 | Traveler entity |
| **22** | PasswordModel | `passwords_box` | Active | 2025-01-27 | Password entity (encrypted) |
| **23** | SecretQuestionModel | `secret_questions_box` | Active | 2025-01-27 | Secret question entity (encrypted) |
| **24** | ExpenseModel | `expenses_tracker_box` | Active | 2025-01-27 | Expense entity for expense tracker |
| **30** | FileServerConfigModel | `file_tracker_config_box` | Active | 2025-01-28 | File server configuration entity |
| **31** | FileMetadataModel | `file_tracker_metadata_box` | Active | 2025-01-28 | File metadata (tags, notes) entity |
| **32** | BookModel | `books_tracker_box` | Active | 2025-01-28 | Book entity for book tracker |
| **33** | ReadHistoryEntryModel | `books_tracker_box` | Active | 2025-01-28 | Read history entry entity (nested in BookModel) |
| **34** | InvestmentMasterModel | `investment_masters_box` | Active | 2025-01-28 | Investment master entity for portfolio tracker |
| **35** | InvestmentLogModel | `investment_logs_box` | Active | 2025-01-28 | Investment log entity for portfolio tracker |
| **36** | RedemptionLogModel | `redemption_logs_box` | Active | 2025-01-28 | Redemption log entity for portfolio tracker |

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
| `investment_components_box` | Investment component entities     | InvestmentComponentModel | Active | Investment component storage |
| `income_categories_box`     | Income category & entry entities  | IncomeCategoryModel, IncomeEntryModel | Active | Income category and entry storage |
| `expense_categories_box`    | Expense category & entry entities | ExpenseCategoryModel, ExpenseEntryModel | Active | Expense category and entry storage |
| `investment_plans_box`      | Investment plan entities         | InvestmentPlanModel | Active | Investment plan storage |
| `retirement_plan_box`       | Retirement plan entities         | RetirementPlanModel | Active | Retirement plan storage |
| `trips_box`                 | Travel trip entities              | TripModel | Active    | Travel trip storage |
| `trip_profiles_box`         | Trip profile entities             | TripProfileModel | Active | Trip profile storage |
| `travelers_box`             | Traveler entities                 | TravelerModel | Active | Traveler storage |
| `itinerary_days_box`        | Itinerary day entities            | ItineraryDayModel | Active | Itinerary day storage |
| `itinerary_items_box`       | Itinerary item entities          | ItineraryItemModel | Active | Itinerary item storage |
| `journal_entries_box`       | Journal entry entities            | JournalEntryModel | Active | Travel journal entry storage |
| `photos_box`                | Photo entities                    | PhotoModel | Active | Travel photo storage |
| `expenses_box`              | Travel expense entities           | ExpenseModel | Active | Travel expense storage |
| `passwords_box`             | Password entities (encrypted)     | PasswordModel | Active | Password storage with encryption |
| `secret_questions_box`      | Secret question entities (encrypted) | SecretQuestionModel | Active | Secret question storage with encryption |
| `expenses_tracker_box`      | Expense entities                  | ExpenseModel | Active | Expense tracker storage |
| `file_tracker_config_box`   | File server configuration entities | FileServerConfigModel | Active | File tracker server configuration storage |
| `file_tracker_config_box_active` | Active file server name | String | Active | Active server selection storage |
| `file_tracker_metadata_box` | File metadata entities (tags, notes) | FileMetadataModel | Active | File metadata storage (server-independent) |
| `books_tracker_box`         | Book entities                      | BookModel | Active | Book tracker storage |
| `investment_masters_box`    | Investment master entities         | InvestmentMasterModel | Active | Portfolio tracker investment master storage |
| `investment_logs_box`       | Investment log entities            | InvestmentLogModel | Active | Portfolio tracker investment log storage |
| `redemption_logs_box`       | Redemption log entities            | RedemptionLogModel | Active | Portfolio tracker redemption log storage |
| `view_preferences_box`      | User view field preferences       | String    | Active    | UI customization settings                  |
| `filter_preferences_box`    | User filter preferences           | String    | Active    | Filter state persistence                   |
| `sort_preferences_box`      | User sort preferences             | String    | Active    | Sort state persistence                     |
| `theme_preferences_box`     | Theme preferences                 | String    | Active    | Theme and font preferences                 |
| `organization_preferences_box` | Organization preferences        | String    | Active    | Module enablement and default home page    |
| `backup_preferences_box`    | Backup preferences                | String    | Active    | Backup configuration settings              |
| `retirement_preferences_box` | Retirement planner preferences   | String    | Active    | Retirement planner configuration           |

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

## 📦 Model: PasswordModel (TypeId: 22)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name          | Type     | Nullable | Default | Notes                                           |
|--------------|---------------------|----------|----------|---------|-------------------------------------------------|
| 0            | `id`                | String   | No       | -       | Unique identifier (GUID)                        |
| 1            | `siteName`          | String   | No       | -       | Human-readable site name                        |
| 2            | `url`               | String   | Yes      | null    | Optional URL for the site                      |
| 3            | `username`          | String   | Yes      | null    | Optional username for the account               |
| 4            | `encryptedPassword` | String   | Yes      | null    | Encrypted password (stored as encrypted string) |
| 5            | `isGoogleSignIn`    | bool     | No       | false   | Whether this account uses Google Sign-In        |
| 6            | `lastUpdated`       | DateTime | No       | -       | Timestamp of last update                        |
| 7            | `is2FA`             | bool     | No       | false   | Whether this account has 2FA enabled             |
| 8            | `categoryGroup`     | String   | Yes      | null    | Optional category/group for the password        |
| 9            | `hasSecretQuestions` | bool   | No       | false   | Whether this password has associated secret questions |

**Business Rules:**
- Password field is encrypted before storage and decrypted when retrieved.
- Encryption is handled by PasswordEncryptionService at the repository layer.
- The model stores `encryptedPassword` as a string; actual password is never stored in plain text.
- `hasSecretQuestions` flag indicates if associated SecretQuestion entities exist.

**Migration History:**
- v1.0 (2025-01-27): Initial schema with 10 fields.

---

## 📦 Model: SecretQuestionModel (TypeId: 23)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name        | Type     | Nullable | Default | Notes                                           |
|--------------|-------------------|----------|----------|---------|-------------------------------------------------|
| 0            | `id`              | String   | No       | -       | Unique identifier (GUID)                        |
| 1            | `passwordId`      | String   | No       | -       | Foreign key linking to parent Password          |
| 2            | `question`        | String   | No       | -       | The secret question text                        |
| 3            | `encryptedAnswer` | String   | No       | -       | Encrypted answer (stored as encrypted string)   |

**Business Rules:**
- Answer field is encrypted before storage and decrypted when retrieved.
- Encryption is handled by PasswordEncryptionService at the repository layer.
- The model stores `encryptedAnswer` as a string; actual answer is never stored in plain text.
- Multiple SecretQuestion entities can be linked to a single Password via `passwordId`.

**Migration History:**
- v1.0 (2025-01-27): Initial schema with 4 fields.

---

## 📦 Model: FileServerConfigModel (TypeId: 30)

### Schema Version: 1.1 (Current)

**Fields:**

| Field Number | Field Name    | Type     | Nullable | Default | Notes                                           |
|--------------|---------------|----------|----------|---------|-------------------------------------------------|
| 0            | `baseUrl`     | String   | No       | -       | Base URL of the file server                     |
| 1            | `username`    | String   | No       | ''      | Username for Basic HTTP Authentication          |
| 2            | `password`    | String   | No       | ''      | Password for Basic HTTP Authentication          |
| 3            | `serverName`  | String?  | Yes      | null    | Unique name/identifier for this server config   |

**Business Rules:**
- `serverName` is used as the key for storing configurations, allowing multiple servers to be configured.
- If `serverName` is null or empty, it is auto-generated from the `baseUrl` (extracts hostname).
- Server configurations are stored by server name, not URL, allowing URL changes without losing configuration.
- Supports multiple named server configurations that can be switched between.
- Old single-server configs (stored with key 'config') are automatically migrated to named servers.

**Migration History:**
- v1.0 (Initial): Fields 0-2 defined (baseUrl, username, password).
- v1.1 (2025-01-28): Added field 3 (serverName) for multiple server support. Field is nullable for backward compatibility.

**Notes:**
- Field order maintained for backward compatibility (baseUrl=0, username=1, password=2, serverName=3).
- Old configs without `serverName` are automatically migrated with auto-generated names.
- The model generates a default server name from URL if not provided during construction.

---

## 📦 Model: FileMetadataModel (TypeId: 31)

### Schema Version: 1.0 (Current)

**Fields:**

| Field Number | Field Name        | Type           | Nullable | Default | Notes                                           |
|--------------|-------------------|----------------|----------|---------|-------------------------------------------------|
| 0            | `stableIdentifier`| String         | No       | -       | Stable identifier (folder + name) for file      |
| 1            | `tags`            | List<String>   | No       | []      | List of tags associated with the file           |
| 2            | `notes`           | String?        | Yes      | null    | Optional notes/description for the file         |
| 3            | `lastUpdated`     | DateTime       | No       | -       | Timestamp when metadata was last updated        |

**Business Rules:**
- `stableIdentifier` is the primary key and is server-independent (format: `{folder}/{name}`).
- Tags persist even when server URLs change or when switching between servers.
- Metadata is stored separately from file listings and is keyed by stable identifier, not server name.
- Tags are shared between servers if they have the same folder structure.
- The stable identifier normalizes folder paths (removes leading/trailing slashes).

**Migration History:**
- v1.0 (2025-01-28): Initial schema with 4 fields.

**Notes:**
- Metadata is stored in a separate Hive box (`file_tracker_metadata_box`) from server configurations.
- The stable identifier ensures tags persist across server URL changes and server switches.
- Example: `/photos/2024/vacation.jpg` on Server A will share tags with the same path on Server B.

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

## 📦 Model: ComponentAllocationModel (TypeId: 12)

### Schema Version: 2.0 (Current)

**Fields:**

| Field Number | Field Name        | Type     | Nullable | Default | Notes                                           |
|--------------|-------------------|----------|----------|---------|-------------------------------------------------|
| 0            | `componentId`     | String   | No       | -       | Reference to the investment component ID        |
| 1            | `allocatedAmount` | double   | No       | -       | Planned allocation amount for this component    |
| 2            | `actualAmount`    | double   | Yes      | null    | Actual investment amount (nullable)             |
| 3            | `isCompleted`     | bool     | No       | false   | Whether this allocation has been completed       |

**Business Rules:**
- `allocatedAmount` represents the planned investment amount calculated based on component priority, percentage, and limits.
- `actualAmount` can only be set when the parent plan status is `approved` or `executed`.
- `isCompleted` is a visual indicator and does not affect plan status.
- Variance is calculated as `allocatedAmount - actualAmount` (positive = under-invested, negative = over-invested).

**Migration History:**
- v1.0 (2025-01-27): Initial schema with 2 fields (componentId, allocatedAmount).
- v2.0 (2025-01-28): Added fields 2-3 (actualAmount, isCompleted) for actual investment tracking.

**Notes:**
- Fields 2-3 are nullable/defaulted to ensure backward compatibility with existing data.
- Old allocations (without fields 2-3) will be read with `actualAmount = null` and `isCompleted = false`.
- The generated Hive adapter automatically handles missing fields in existing data.

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
- **6**: InvestmentComponentModel
- **7**: IncomeCategoryModel
- **8**: ExpenseCategoryModel
- **9**: InvestmentPlanModel
- **10**: IncomeEntryModel
- **11**: ExpenseEntryModel
- **12**: ComponentAllocationModel
- **13**: RetirementPlanModel
- **14**: TripModel
- **15**: TripProfileModel
- **16**: ItineraryDayModel
- **17**: ItineraryItemModel
- **18**: JournalEntryModel
- **19**: PhotoModel
- **20**: ExpenseModel
- **21**: TravelerModel
- **22**: PasswordModel
- **23**: SecretQuestionModel
- **24**: ExpenseModel (expense tracker)
- **30**: FileServerConfigModel
- **31**: FileMetadataModel
- **Next Available**: 32

### Current Box Names
- `goals_box` - Goal entities
- `milestones_box` - Milestone entities
- `tasks_box` - Task entities
- `habits_box` - Habit entities
- `habit_completions_box` - Habit completion entities
- `backup_metadata_box` - Backup metadata
- `investment_components_box` - Investment component entities
- `income_categories_box` - Income category and entry entities
- `expense_categories_box` - Expense category and entry entities
- `investment_plans_box` - Investment plan entities
- `retirement_plan_box` - Retirement plan entities
- `trips_box` - Travel trip entities
- `trip_profiles_box` - Trip profile entities
- `travelers_box` - Traveler entities
- `itinerary_days_box` - Itinerary day entities
- `itinerary_items_box` - Itinerary item entities
- `journal_entries_box` - Journal entry entities
- `photos_box` - Photo entities
- `expenses_box` - Travel expense entities
- `passwords_box` - Password entities (encrypted)
- `secret_questions_box` - Secret question entities (encrypted)
- `expenses_tracker_box` - Expense tracker entities
- `file_tracker_config_box` - File server configuration entities
- `file_tracker_config_box_active` - Active file server name
- `file_tracker_metadata_box` - File metadata entities (tags, notes)
- `view_preferences_box` - UI preferences
- `filter_preferences_box` - Filter preferences
- `sort_preferences_box` - Sort preferences
- `theme_preferences_box` - Theme preferences
- `organization_preferences_box` - Organization preferences
- `backup_preferences_box` - Backup preferences
- `retirement_preferences_box` - Retirement planner preferences

### Key Files to Update
1. `migration_notes.md` - This file (TypeId and schema documentation)
2. Module-specific `constants.dart` files - Box name constants (e.g., `lib/trackers/goal_tracker/core/constants.dart`, `lib/trackers/password_tracker/core/constants.dart`)
3. `lib/core/hive_initializer.dart` - Central Hive initializer that discovers module initializers
4. Module-specific `hive_initializer.dart` files - Adapter registration and box opening (e.g., `lib/trackers/password_tracker/core/hive_initializer.dart`)
5. Module-specific `injection.dart` files - Dependency injection wiring

---

**Last Updated:** 2025-01-28  
**Version:** 3.1  
**Maintained by:** Development Team  
**Review Frequency:** On every schema change  
**Next Review:** On next model addition

