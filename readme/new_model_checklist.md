# 🧭 New Model Implementation Checklist (Clean Architecture)

This guide outlines the **end-to-end process** for adding a new model (e.g., *Milestone*, *Task*, *Project*) to the app. It mirrors the structure used for `Goal` and ensures consistency across all layers: **Domain → Data → Presentation → Core**.

---

## ✅ CLEAN ARCHITECTURE DEVELOPMENT CHECKLIST

### 📦 For Adding a New Model (e.g., Milestone, Task, Project)

---

### **1️⃣ Domain Layer — Core Entity Definition**

**Purpose:** Define the pure domain-level representation (immutable, no persistence logic).

#### Steps

* [ ] Create file: `lib/goal_tracker/domain/entities/<entity_name>.dart`
* [ ] Follow same structure and doc style as `goal.dart`
* [ ] Extend `Equatable` for value comparison
* [ ] Include only plain fields — no annotations or Hive references
* [ ] Example fields:

  ```dart
  final String id;
  final String name;
  final String? description;
  final DateTime? targetDate;
  final double? plannedValue;
  final double? actualValue;
  final String? goalId;
  ```

---

### **2️⃣ Data Layer — Hive Model**

**Purpose:** Define Hive persistence model mapped to the domain entity.

#### Steps

* [ ] Create `lib/goal_tracker/data/models/<entity_name>_model.dart`
* [ ] Annotate with `@HiveType(typeId: X)` (assign unique typeId, record in `migration_notes.md`)
* [ ] Add `@HiveField(N)` for each field
* [ ] Add `fromEntity()` and `toEntity()` converters
* [ ] Add `part '<entity_name>_model.g.dart';` for code generation
* [ ] Run codegen:

  ```bash
  flutter packages pub run build_runner build --delete-conflicting-outputs
  ```
* [ ] **CRITICAL**: Update `migration_notes.md` with new TypeId and schema documentation

---

### **3️⃣ Data Layer — Local Data Source**

**Purpose:** Encapsulate CRUD operations against Hive box.

#### Steps

* [ ] Create `lib/goal_tracker/data/datasources/<entity_name>_local_data_source.dart`
* [ ] Define abstract class for CRUD operations
* [ ] Implement `<Entity>LocalDataSourceImpl` with a `Box<<Entity>Model>`

---

### **4️⃣ Data Layer — Repository Implementation**

**Purpose:** Bridge data source ↔ domain layer.

#### Steps

* [ ] Create `lib/goal_tracker/data/repositories/<entity_name>_repository_impl.dart`
* [ ] Import entity, data source, and model
* [ ] Implement repository methods converting model ↔ entity

---

### **5️⃣ Domain Layer — Repository Interface**

**Purpose:** Define the domain contract for persistence.

#### Steps

* [ ] Create `lib/goal_tracker/domain/repositories/<entity_name>_repository.dart`
* [ ] Define CRUD methods:

  ```dart
  abstract class <Entity>Repository {
    Future<List<<Entity>>> getAll<Entity>s();
    Future<<Entity>?> get<Entity>ById(String id);
    Future<void> create<Entity>(<Entity> entity);
    Future<void> update<Entity>(<Entity> entity);
    Future<void> delete<Entity>(String id);
  }
  ```

---

### **6️⃣ Domain Layer — Use Cases**

**Purpose:** Encapsulate single-responsibility domain operations.

#### Steps

* [ ] Create directory: `lib/goal_tracker/domain/usecases/<entity_name>/`
* [ ] Add:

  * `get_all_<entity>s.dart`
  * `get_<entity>_by_id.dart`
  * `create_<entity>.dart`
  * `update_<entity>.dart`
  * `delete_<entity>.dart`
* [ ] **Optional**: Add relationship-specific use cases (e.g., `get_<entity>s_by_goal_id.dart`)
* [ ] Each wraps a repository call:

  ```dart
  Future<void> call(<Entity> entity);
  ```
* [ ] **For complex entities**: Consider business rules (e.g., Task auto-assignment of goalId)

---

### **7️⃣ Presentation Layer — State Management**

**Purpose:** Represent UI state transitions.

#### Steps

* [ ] Create `lib/goal_tracker/presentation/bloc/<entity_name>_state.dart`

  * Include `<Entity>sLoading`, `<Entity>sLoaded`, `<Entity>sError`
  * Extend `Equatable`
* [ ] Create `lib/goal_tracker/presentation/bloc/<entity_name>_cubit.dart`

  * Inject use cases (getAll, create, update, delete)
  * Inject preference services (ViewPreferencesService, FilterPreferencesService, SortPreferencesService)
  * Maintain master list `_all<Entity>s`
  * Implement methods for load, add, edit, remove
  * Implement filtering, sorting, and view field management
  * **For complex entities**: Handle business rules (e.g., auto-assignment logic)

---

### **8️⃣ Presentation Layer — UI Components**

**Purpose:** Define the entity-specific form and list widgets.

#### Steps

* [ ] Create:

  * `widgets/<entity_name>_form_bottom_sheet.dart`
  * `widgets/<entity_name>_list_item.dart`
* [ ] Follow `goal_form_bottom_sheet.dart` and `goal_list_item.dart`
* [ ] Adjust visible fields, labels, and bindings
* [ ] Use goal name instead of goal ID where needed for readability
* [ ] **For complex entities**: Implement business rule constraints (e.g., read-only fields, auto-assignment)
* [ ] Add proper validation and error handling
* [ ] Consider accessibility and responsive design

---

### **9️⃣ Presentation Layer — List Page**

**Purpose:** Main screen listing entities.

#### Steps

* [ ] Create `pages/<entity_name>_list_page.dart`
* [ ] Copy structure from `goal_list_page.dart`
* [ ] Wire up `BlocProvider` with `create<Entity>Cubit()`
* [ ] Render entity list, handle add/edit/filter actions
* [ ] Use reusable components (`PrimaryAppBar`, `LoadingView`, etc.)
* [ ] Implement filtering and sorting UI
* [ ] Add view field customization options
* [ ] Handle empty states and error states

---

### **🔟 Core — Dependency Injection**

**Purpose:** Wire model → repo → usecases → cubit.

#### Steps

* [ ] Update `core/injection.dart`

  * Add `create<Entity>Cubit()` factory
  * Register data source → repo → usecases → cubit chain
  * Inject preference services (ViewPreferencesService, FilterPreferencesService, SortPreferencesService)
* [ ] Example:

  ```dart
  final local = MilestoneLocalDataSourceImpl(box);
  final repo = MilestoneRepositoryImpl(local);
  final create = CreateMilestone(repo);
  return MilestoneCubit(
    getAll: getAll, 
    create: create, 
    viewPreferencesService: getViewPreferencesService(),
    filterPreferencesService: getFilterPreferencesService(),
    sortPreferencesService: getSortPreferencesService(),
    ...
  );
  ```

---

### **11️⃣ Core — Hive Initializer**

**Purpose:** Register Hive adapters and open boxes.

#### Steps

* [ ] Update `core/hive_initializer.dart`

  * Register `<Entity>ModelAdapter()`
  * Open box: `Hive.openBox<<Entity>Model>('<entity>s_box')`
  * Print all entries to console:

    ```dart
    print('📦 <Entity>s Box (${box.length} entries)');
    ```
* [ ] **CRITICAL**: Update `lib/goal_tracker/core/constants.dart` with new box name constant

---

### **12️⃣ Presentation — Home Page Navigation**

**Purpose:** Add entry point navigation for new module.

#### Steps

* [ ] Update `presentation/pages/home_page.dart`

  * Add new button:

    ```dart
    ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const <Entity>ListPage()),
      ),
      child: const Text('<Entity>s'),
    );
    ```

---

### **13️⃣ Testing — Unit & Widget Tests**

**Purpose:** Ensure code quality and prevent regressions.

#### Steps

* [ ] Create `test/<entity_name>_repository_test.dart`
  * Test all CRUD operations
  * Test entity ↔ model conversion
  * Test error handling
* [ ] Create `test/<entity_name>_cubit_test.dart`
  * Test state transitions (loading → loaded → error)
  * Test business rules (e.g., auto-assignment logic)
  * Test filtering and sorting
* [ ] Create `test/<entity_name>_form_bottom_sheet_test.dart`
  * Test form validation
  * Test business rule constraints (e.g., read-only fields)
  * Test user interactions

---

### **14️⃣ Import/Export — Data Portability**

**Purpose:** Enable data import/export functionality.

#### Steps

* [ ] Create `lib/goal_tracker/features/<entity_name>_import_export.dart`
* [ ] Implement CSV/Excel export functionality
* [ ] Implement CSV/Excel import functionality
* [ ] Add data validation for imports
* [ ] Handle error cases and user feedback

---

### **15️⃣ Optional — Utility Additions**

**Purpose:** Extend functionality.

* [ ] Add advanced filtering options
* [ ] Add custom sorting options
* [ ] Add view field customization
* [ ] Add analytics and reporting features
* [ ] Document new typeId and schema in `migration_notes.md`

---

### **🚨 Business Rules & Error Handling**

**Purpose:** Implement complex business logic and proper error handling.

#### Common Patterns

* [ ] **Auto-Assignment Logic**: For entities with relationships (e.g., Task → Milestone → Goal)
  * Implement in Cubit methods (not in UI)
  * Fetch parent entity to derive relationships
  * Handle missing parent entities gracefully
* [ ] **Validation Rules**: Implement both client-side and server-side validation
  * Required fields
  * Data format validation
  * Business rule validation
* [ ] **Error Handling**: Implement comprehensive error handling
  * Custom exception classes
  * User-friendly error messages
  * Graceful degradation
* [ ] **Data Integrity**: Ensure data consistency
  * Foreign key constraints
  * Cascade operations
  * Soft delete patterns

#### Example: Task Auto-Assignment

```dart
// In TaskCubit
Future<void> addTask({
  required String name,
  required String milestoneId,
  // ... other fields
}) async {
  try {
    // 1. Fetch milestone to get goalId
    final milestone = await milestoneRepository.getMilestoneById(milestoneId);
    if (milestone == null) {
      throw MilestoneNotFoundException(milestoneId);
    }
    
    // 2. Auto-assign goalId from milestone
    final task = Task(
      id: const Uuid().v4(),
      name: name,
      milestoneId: milestoneId,
      goalId: milestone.goalId, // Auto-assigned
      // ... other fields
    );
    
    await create(task);
    await loadTasks();
  } catch (e) {
    emit(TasksError(e.toString()));
  }
}
```

---

### **📁 Example Folder Layout**

```
goal_tracker/
 ├── core/
 │    ├── constants.dart
 │    ├── injection.dart
 │    ├── hive_initializer.dart
 │
 ├── data/
 │    ├── datasources/
 │    │     ├── goal_local_data_source.dart
 │    │     ├── milestone_local_data_source.dart
 │    │     ├── task_local_data_source.dart
 │    ├── models/
 │    │     ├── goal_model.dart
 │    │     ├── milestone_model.dart
 │    │     ├── task_model.dart
 │    ├── repositories/
 │          ├── goal_repository_impl.dart
 │          ├── milestone_repository_impl.dart
 │          ├── task_repository_impl.dart
 │
 ├── domain/
 │    ├── entities/
 │    ├── repositories/
 │    ├── usecases/
 │          ├── goal/
 │          ├── milestone/
 │          ├── task/
 │
 ├── presentation/
 │    ├── bloc/
 │    ├── widgets/
 │    ├── pages/
 │
 └── main.dart
```

---

### **🧩 Naming Rules**

| Layer       | Naming Convention             | Example                        |
| ----------- | ----------------------------- | ------------------------------ |
| Entity      | `<Entity>`                    | `Milestone`                    |
| Model       | `<Entity>Model`               | `MilestoneModel`               |
| Data Source | `<Entity>LocalDataSourceImpl` | `MilestoneLocalDataSourceImpl` |
| Repository  | `<Entity>RepositoryImpl`      | `MilestoneRepositoryImpl`      |
| Use Case    | `<Action><Entity>`            | `CreateMilestone`              |
| State       | `<Entity>sLoaded`             | `MilestonesLoaded`             |
| Cubit       | `<Entity>Cubit`               | `MilestoneCubit`               |
| Form Widget | `<Entity>FormBottomSheet`     | `MilestoneFormBottomSheet`     |
| List Widget | `<Entity>ListItem`            | `MilestoneListItem`            |
| Page        | `<Entity>ListPage`            | `MilestoneListPage`            |

---

✅ **Summary:**
Follow this checklist sequentially whenever adding a new model. Each section ensures the model is correctly integrated from storage to UI while preserving the clean architecture boundaries and consistent project structure.

**Key Updates in This Version:**
- ✅ Added migration notes documentation requirements
- ✅ Added preference services integration (View, Filter, Sort)
- ✅ Added comprehensive testing patterns
- ✅ Added import/export functionality
- ✅ Added business rules and error handling patterns
- ✅ Added constants management
- ✅ Added complex entity relationship handling
- ✅ Added accessibility and validation considerations

**Critical Dependencies:**
- `migration_notes.md` - Must be updated for every new model
- `constants.dart` - Must include box name constants
- Preference services - Required for filtering and view management
- Comprehensive testing - Essential for code quality
