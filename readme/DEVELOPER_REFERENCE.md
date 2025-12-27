# Developer Reference — Models, Use Cases, and UI Components

This document is the **developer-facing reference** for the `all_tracker` Flutter app. It focuses on:

- **Models**: Domain entities vs. Hive persistence models (DTOs), converters, and migration rules.
- **Functions**: Domain “use cases” (single-responsibility operations) and service functions.
- **Components**: Cubits, pages, and reusable widgets—with practical examples.

If you’re new to this repo, start with:

- `ARCHITECTURE.md` (high-level architecture)
- `migration_notes.md` (Hive TypeId + box registry)
- `readme/new_model_checklist.md` (step-by-step guide to adding a new model)

---

## Quick start (dev workflow)

- **Install dependencies**

```bash
flutter pub get
```

- **Generate Hive adapters / other codegen**

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

- **Run**

```bash
flutter run
```

- **Analyze + test**

```bash
flutter analyze
flutter test
```

---

## Architecture recap (how things are organized)

The project is modular. Most “features” follow the same clean-architecture slice:

```
<module>/
  core/          # constants, Hive initializer, and composition root (injection)
  domain/        # entities, repository interfaces, use cases (pure Dart)
  data/          # Hive models (DTOs), datasources, repository implementations
  presentation/  # Cubits/States + pages/widgets
  features/      # optional: import/export, reporting, specialized logic
```

Examples in this repo:

- Trackers: `lib/trackers/*_tracker/`
- Utilities: `lib/utilities/*/`
- Cross-cutting features: `lib/features/*/` (e.g., `auth`, `backup`)
- Shared app core: `lib/core/`
- Shared widgets: `lib/widgets/`

---

## App bootstrap and runtime wiring

### `main.dart` (app startup)

`lib/main.dart` does (in order):

- **Hive initialization** (`HiveInitializer.initialize()`) to register adapters and open boxes.
- **DI configuration** (`configureDependencies()`) for shared services (preferences, box provider).
- **Global providers**:
  - `ThemeNotifier` (theme + fonts)
  - `OrganizationNotifier` (module enablement toggles + default home page)
  - `AuthCubit` (Google sign-in flow)
- **Backup automation hooks**:
  - Runs automatic backup on `paused`
  - Checks for restore on `resumed` and startup delay

### Hive initialization (module discovery pattern)

`lib/core/hive_initializer.dart` uses a **module initializer** pattern:

- Each module implements `HiveModuleInitializer` (`lib/core/hive/hive_module_initializer.dart`)
- The central `HiveInitializer` calls:
  - `registerAdapters()` for every module
  - `openBoxes()` for every module

When you add a new Hive model/box, you usually update:

- `migration_notes.md` (TypeId + box registry)
- `<module>/core/hive_initializer.dart` (register adapter + open box)
- `lib/core/hive_initializer.dart` (add your module initializer to the list)

### Dependency injection (two styles in this repo)

- **App-wide shared services** (GetIt container): `lib/core/injection.dart`
  - `BoxProvider`
  - `ViewPreferencesService`
  - `FilterPreferencesService`
  - `SortPreferencesService`

- **Feature composition roots** (manual factory functions): many modules expose `createXyzCubit()` factories in `<module>/core/injection.dart`.
  - Example: `lib/trackers/expense_tracker/core/injection.dart`
  - Example: `lib/features/backup/core/injection.dart`

This hybrid approach keeps:

- “shared infrastructure” in GetIt,
- “feature wiring” close to the feature.

---

## Models (entities, Hive models, and migrations)

### Domain entities (what the app “means”)

Domain entities live under `<module>/domain/entities/` and should be:

- **Immutable**
- **Equatable**
- **Free of persistence annotations** (no Hive, no JSON annotations in domain)

Example: `Expense` (`lib/trackers/expense_tracker/domain/entities/expense.dart`)

- Core fields:
  - `id`, `date`, `description`, `amount`, `group`, `createdAt`, `updatedAt`
- Convenience getters:
  - `isDebit` / `isCredit`

### Hive models (what the app stores)

Hive models live under `<module>/data/models/` and are responsible for:

- Hive annotations (`@HiveType`, `@HiveField`)
- Schema stability
- Mapping:
  - `fromEntity()` (domain → model)
  - `toEntity()` (model → domain)

Example: `ExpenseModel` (`lib/trackers/expense_tracker/data/models/expense_model.dart`)

- Uses `@HiveType(typeId: 24)` (see `migration_notes.md`)
- Stores enum as string (`group: expense.group.name`)
- Has a safe fallback when decoding legacy/unknown enum values

### TypeIds and box names (single source of truth)

`migration_notes.md` is the **TypeId registry** and **box registry**. Rules:

- **Never reuse TypeIds**
- **Never reorder HiveField indices**
- Prefer **additive** schema changes (new nullable fields at the end)

### Code generation (Hive adapters)

Hive adapters are generated into `*.g.dart` files. Regenerate when you add/change a Hive model:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Storage conventions used in this repo

- **Hive keys**: often the entity `id` string is used as the Hive key (stable across sessions).
- **Enum persistence**: most models store enums as `.name` strings; converters should handle unknown values gracefully.
- **Preferences**: stored as primitive types (strings, bools, small maps) in dedicated boxes.

---

## Functions (use cases and services)

### Use cases (domain “functions”)

Use cases live under `<module>/domain/usecases/...` and follow this convention:

- Wrap a single application action (CRUD, queries, calculations)
- Depend only on the **domain repository interface**
- Expose a `call(...)` method

Example: `GetExpenseInsights` (`lib/trackers/expense_tracker/domain/usecases/expense/get_expense_insights.dart`)

- Inputs: optional `group`, `start`, `end`
- Output: `ExpenseInsights` with totals, counts, and percentages

Example: `CreateBackup` (`lib/features/backup/domain/usecases/create_backup.dart`)

- Inputs: `mode`, optional `passphrase`, optional `name`
- Output: `BackupResult` (success/failure)

### Services (cross-cutting or infrastructure)

Services typically live under `lib/core/services/` or `<feature>/core/`.

Example: `EncryptionService` (`lib/features/backup/core/encryption_service.dart`)

- AES-256-GCM via `cryptography`
- Two modes:
  - **Device Key**: generated and stored in `flutter_secure_storage`
  - **E2EE**: PBKDF2-derived key from passphrase

---

## Components (Cubit/State, pages, widgets)

### Cubits (state orchestration)

Cubits live under `<module>/presentation/bloc/` (or `presentation/cubit/`) and:

- call use cases
- transform results to UI states
- hold any UI-oriented derived data (filters, view-model shaping)

Example: `ExpenseCubit` (`lib/trackers/expense_tracker/presentation/bloc/expense_cubit.dart`)

- Maintains a master list `_allExpenses`
- Exposes methods:
  - `loadExpenses()`, `createExpense(...)`, `updateExpense(...)`, `deleteExpense(...)`

Example: `BackupCubit` (`lib/features/backup/presentation/cubit/backup_cubit.dart`)

- Handles:
  - Google sign-in state
  - listing backups
  - create/restore/delete
  - preference updates for auto backup + retention

### Pages (navigation destinations)

Pages typically live under `<module>/presentation/pages/` (or `lib/pages/` for global pages).

Global:

- `lib/pages/app_home_page.dart` (grid of trackers/utilities)
- `lib/pages/settings_page.dart` (theme/font, module toggles, backup config)

### Reusable widgets

Shared widgets are in `lib/widgets/`.

Two common patterns:

- **Bottom sheets**: `showAppBottomSheet<T>()` (`lib/widgets/bottom_sheet_helpers.dart`)
- **Standard buttons**: `PrimaryElevatedButton` (`lib/widgets/primary_elevated_button.dart`)

---

## Example: Expense Tracker (end-to-end)

### What it does

The Expense Tracker stores simple transactions and renders:

- list of expenses
- dashboard insights (totals, group breakdown, date range filtering)

### Key files (map of responsibilities)

- **Domain**
  - `domain/entities/expense.dart`
  - `domain/entities/expense_group.dart`
  - `domain/repositories/expense_repository.dart`
  - `domain/usecases/expense/*`
- **Data**
  - `data/models/expense_model.dart` (Hive model, TypeId: 24)
  - `data/datasources/expense_local_data_source.dart`
  - `data/repositories/expense_repository_impl.dart`
- **Presentation**
  - `presentation/bloc/expense_cubit.dart`
  - `presentation/widgets/expense_list_item.dart`
  - `presentation/pages/expense_list_page.dart`
  - `presentation/bloc/expense_insights_cubit.dart` + state
- **Composition root**
  - `core/hive_initializer.dart`
  - `core/injection.dart`

### Creating and using the cubit (UI example)

In a page widget, wire it like this:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_tracker/trackers/expense_tracker/core/injection.dart';
import 'package:all_tracker/trackers/expense_tracker/presentation/bloc/expense_cubit.dart';
import 'package:all_tracker/trackers/expense_tracker/presentation/bloc/expense_state.dart';
import 'package:all_tracker/trackers/expense_tracker/presentation/widgets/expense_list_item.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createExpenseCubit()..loadExpenses(),
      child: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpensesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpensesError) {
            return Center(child: Text(state.message));
          }
          if (state is ExpensesLoaded) {
            final expenses = state.expenses;
            return ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, i) => ExpenseListItem(
                expense: expenses[i],
                onTap: () {
                  // show edit sheet, open details page, etc.
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### Creating a new expense (Cubit call example)

```dart
context.read<ExpenseCubit>().createExpense(
  date: DateTime.now(),
  description: 'Coffee',
  amount: 4.50,
  group: ExpenseGroup.food,
);
```

---

## Example: Cloud Backup feature (models + services + Cubit)

### What it does

The Backup feature (`lib/features/backup/`) implements:

- Google Drive auth + Drive API access
- Encrypted backup creation (device-key or E2EE)
- Restore and delete
- Automatic backup scheduling (app lifecycle driven)
- Local tracking of backup metadata in Hive (`backup_metadata_box`)

### Key files

- **Models**
  - `data/models/backup_metadata_model.dart` (Hive, TypeId: 5)
- **Core services**
  - `core/encryption_service.dart` (AES-256-GCM + PBKDF2)
  - `core/backup_preferences_service.dart` (auto backup, mode, retention)
  - `core/backup_scheduler_service.dart` (automatic backup + cleanup)
- **Use cases**
  - `domain/usecases/create_backup.dart`
  - `domain/usecases/list_backups.dart`
  - `domain/usecases/restore_backup.dart`
  - `domain/usecases/delete_backup.dart`
- **Presentation**
  - `presentation/cubit/backup_cubit.dart`
  - `presentation/pages/backup_settings_page.dart`

### Using BackupCubit (UI example)

```dart
BlocProvider(
  create: (_) => createBackupCubit()..checkAuthStatus(),
  child: BlocBuilder<BackupCubit, BackupState>(
    builder: (context, state) {
      if (state is BackupSigningIn) return const Text('Signing in...');
      if (state is BackupSignedIn) return Text('Signed in as ${state.accountEmail}');
      if (state is BackupSignedOut) return const Text('Signed out');
      if (state is BackupError) return Text(state.message);
      return const SizedBox.shrink();
    },
  ),
)
```

### Triggering an encrypted backup (example)

```dart
context.read<BackupCubit>().createBackup(
  mode: BackupMode.e2ee,
  passphrase: 'correct horse battery staple',
  name: 'Before vacation',
);
```

**Note:** automatic backups won’t prompt for a passphrase; if user selects E2EE, automatic backups fall back to device-key mode.

---

## Module catalog (what exists today)

### Trackers (`lib/trackers/…`)

- **Goal Tracker** (`goal_tracker`)
  - **Purpose**: goals → milestones → tasks + habits + habit completion
  - **Hive**: `GoalModel` (0), `MilestoneModel` (1), `TaskModel` (2), `HabitModel` (3), `HabitCompletionModel` (4)
  - **Notable business rules**:
    - `Task.goalId` and `Habit.goalId` are **derived** from their Milestone
    - Habit completions affect milestone progress (see domain use cases)

- **Travel Tracker** (`travel_tracker`)
  - **Purpose**: trips, travelers, itinerary, journal, photos, travel expenses
  - **Hive**: `TripModel` (14), `TripProfileModel` (15), `ItineraryDayModel` (16), `ItineraryItemModel` (17), `JournalEntryModel` (18), `PhotoModel` (19), `ExpenseModel` (20), `TravelerModel` (21)

- **Expense Tracker** (`expense_tracker`)
  - **Purpose**: simple expense list + insights
  - **Hive**: `ExpenseModel` (24), box `expenses_tracker_box`

- **Password Tracker** (`password_tracker`)
  - **Purpose**: encrypted password storage + secret questions
  - **Hive**: `PasswordModel` (22), `SecretQuestionModel` (23)
  - **Security rule**: plain-text secrets should never be persisted; encrypt at repository/service layer.

- **File Tracker** (`file_tracker`)
  - **Purpose**: browse cloud/server files + attach tags/notes locally
  - **Hive**:
    - `FileServerConfigModel` (30): server configs (supports multiple named servers)
    - `FileMetadataModel` (31): tags/notes keyed by a stable identifier

- **Book Tracker** (`book_tracker`)
  - **Purpose**: track books + reading history
  - **Hive**:
    - `BookModel` (32)
    - `ReadHistoryEntryModel` (33)

### Utilities (`lib/utilities/…`)

- **Investment Planner** (`investment_planner`)
  - **Hive**: `InvestmentComponentModel` (6), `IncomeCategoryModel` (7), `ExpenseCategoryModel` (8), `InvestmentPlanModel` (9), `IncomeEntryModel` (10), `ExpenseEntryModel` (11), `ComponentAllocationModel` (12)

- **Retirement Planner** (`retirement_planner`)
  - **Hive**: `RetirementPlanModel` (13)
  - **Use case**: `calculate_retirement_plan.dart` (domain)

### Features (`lib/features/…`)

- **Auth** (`auth`)
  - **Purpose**: Google Sign-In auth state for the app
  - **Primary component**: `AuthCubit`

- **Backup** (`backup`)
  - documented in detail above

---

## Adding a new model (copy/paste checklist + where to wire it)

Use `readme/new_model_checklist.md` as the canonical checklist. In practice, you’ll touch:

- **Domain**
  - `domain/entities/<entity>.dart`
  - `domain/repositories/<entity>_repository.dart`
  - `domain/usecases/<entity>/*`
- **Data**
  - `data/models/<entity>_model.dart` + generated adapter
  - `data/datasources/<entity>_local_data_source.dart`
  - `data/repositories/<entity>_repository_impl.dart`
- **Hive + migrations**
  - add a new TypeId + box name to `migration_notes.md`
  - register adapter + open box in `<module>/core/hive_initializer.dart`
  - ensure the module initializer is included by `lib/core/hive_initializer.dart`
- **Presentation**
  - `presentation/bloc/<entity>_cubit.dart` + `<entity>_state.dart`
  - `presentation/pages/<entity>_list_page.dart`
  - `presentation/widgets/*` (list item, form sheet)
- **Navigation**
  - add entry in `lib/pages/app_home_page.dart` and/or `lib/widgets/app_drawer.dart` if it’s a user-facing module
- **Tests**
  - follow `test/` conventions (repository tests, cubit tests, widget tests)

---

## Conventions and gotchas

- **Hot reload & Hive**: some feature injection factories guard with `Hive.isBoxOpen(...)` and will throw during hot reload. Restarting the app re-initializes boxes cleanly.
- **Schema discipline**: TypeId + HiveField indices must stay stable. Treat `migration_notes.md` as part of the API.
- **Domain purity**: keep Flutter/Hive out of domain entities and use cases.
- **Prefer small, composable use cases**: calculations (insights, progress) should live in domain use cases, not widgets.

