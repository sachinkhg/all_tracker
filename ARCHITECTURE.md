# Architecture — all_tracker

This document describes the structural design, module responsibilities, data flow, and key entry points for the **All Tracker** application.

---

## Overview

**All Tracker** follows a **modular clean architecture**, separating concerns across `core`, `goal_management`, and `portfolio_management` layers.  
Each module maintains its own domain, data, and presentation layers, ensuring flexibility and scalability for new features.

---

## Layered Architecture

### 1. **Core (App-Level)**

Responsible for global app configurations, dependency injection, theme setup, and common utilities.

**Responsibilities:**
- App-wide constants (colors, fonts, typography, etc.)
- Theme & typography setup
- Hive initialization and configuration
- Dependency injection (DI container)
- Global error handling, navigation setup

**Key Files:**
- `core/injection.dart` — registers repositories and services.
- `core/theme/` — defines app-wide theme and styles.
- `core/constants.dart` — static configuration constants.

---

### 2. **Goal Management Module**

Handles all functionality related to **goals, habits, milestones, and tasks**.  
Implements full clean architecture with domain-driven design (DDD) principles.

**Submodules and Responsibilities:**

#### `core/`
- Constants and dependency setup specific to the goal module.
- Handles Hive adapters and storage registration.

#### `data/`
- Responsible for persistence and communication with data sources (local/remote).
- Includes mappers between data models and domain entities.

**Subfolders:**
- `datasources/` — Data sources (Hive adapters, JSON import/export, REST API calls if added).
- `models/` — Data Transfer Objects (DTOs) and Hive entities.
- `repositories/` — Implements abstract repositories from domain layer.

#### `domain/`
- Core business logic — completely independent from Flutter or external dependencies.
- Defines entities, repository interfaces, and use cases.

**Subfolders:**
- `entities/` — Defines `Goal`, `Milestone`, `Task`, etc.
- `repositories/` — Abstract repository definitions.
- `usecases/` — Application-specific business actions (AddGoal, GetAllGoals, UpdateGoal, etc.).

#### `features/`
- Specialized feature logic that requires additional processing beyond base CRUD.
- Examples: goal import/export, filtering, field configuration persistence, data migration.

#### `presentation/`
- Flutter UI layer implementing state management (BLoC/Cubit).
- Includes widgets, pages, and forms for interacting with goal data.

**Subfolders:**
- `bloc/` — Cubits and Blocs for goal state management.
- `pages/` — Goal screens such as List, Detail, and Add/Edit.
- `widgets/` — Goal-specific widgets like `GoalListItem`, `GoalFormBottomSheet`, etc.

---

### 3. **Portfolio Management Module**

A planned module for financial tracking — managing **investments, liabilities, income, and expenses**.  
Follows the same modular and layered structure as the Goal Management module for consistency.

**Planned Responsibilities:**
- Track and categorize income, expenses, and liabilities.
- Display aggregated dashboards and insights.
- Enable import/export for financial records.

**Submodules (to be implemented):**
- `core/` — module setup and dependency injection.
- `data/` — data sources (Hive, CSV, APIs).
- `domain/` — entities like Investment, Expense, Liability.
- `presentation/` — dashboard and visualization UI.

---

### 4. **Util**

App-wide helper functions and classes.

**Responsibilities:**
- Common utility functions (date/time helpers, formatters, parsers, etc.)
- Extensions and reusable helpers.

---

### 5. **Widgets**

Reusable, app-wide UI components that are shared across modules.

**Examples:**
- Buttons, dropdowns, modals, date pickers, and form components.
- Typically stateless and designed for consistency.

---

### 6. **Main Entry Point**

`main.dart` is the root of the application.

**Responsibilities:**
- Initializes Hive and dependency injection.
- Sets up global theme and routes.
- Boots the initial feature module (Goal Management).

---

## Data Flow Summary

```
UI (Presentation Layer)
    ↓
Use Case (Domain Layer)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
Datasource (Hive / API / Import)
```

- **Presentation Layer:** Reacts to user input via BLoC/Cubit and triggers domain use cases.
- **Domain Layer:** Executes business rules and abstracts implementation details.
- **Data Layer:** Retrieves and persists data through concrete data sources (Hive, API, etc.).

---

## State Management

- **flutter_bloc** is used for structured state management.
- Each module defines its own Cubits and States.
- Example: `GoalCubit` handles all state changes for goals.

---

## Persistence & Import/Export

- Hive is used as the primary persistence layer.
- Import/export features (CSV/JSON) are implemented under `goal_management/features/import_export`.
- Migration logic ensures compatibility across app versions.

---

## Third-Party Libraries (Typical)

- `flutter_bloc` — state management
- `intl` — date formatting
- `hive` — local storage
- `path_provider` — file access for import/export
- `equatable` — equality comparison for entities

---

## Scalability & Extension

- Each new domain (e.g., Portfolio Management) can be added as a self-contained module.
- Follow the same data/domain/presentation structure.
- Encourages isolation and reusability.

---

## Key Entry Points

- **`main.dart`** — Application entry and dependency setup.
- **`core/injection.dart`** — DI container configuration.
- **`goal_management/presentation/pages/`** — Starting point for Goal Management UI.
- **`goal_management/domain/usecases/`** — Core business logic.

---

## Summary

All Tracker’s architecture ensures:
- **Scalability** — new modules can be added independently.
- **Testability** — each layer can be unit tested separately.
- **Maintainability** — separation of concerns across layers.
- **Reusability** — shared utilities and widgets across modules.

---

**Next Steps:**  
Implement the Portfolio Management module mirroring the same clean architecture pattern.
