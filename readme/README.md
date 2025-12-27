# all_tracker

A comprehensive **Flutter** app for tracking progress and productivity — across both **personal goals** and **financial portfolios**.  
This repository includes mobile (Android & iOS) and web builds powered by Flutter.

---

## What this project is

**All Tracker** is a modular productivity and finance management platform built with **Flutter**, designed to unify personal goal tracking and portfolio management.

### Current & Planned Modules

- **Goal Tracker** — Complete goal, milestone, and task management system.  
  *(Status: ✅ Implemented)*  
  - Create and monitor personal or professional goals with hierarchical structure (Goal → Milestone → Task).  
  - Define milestones (time- or metric-based) within each goal.  
  - Add and manage tasks under each milestone with automatic goal assignment.  
  - Advanced filtering, sorting, and customizable view fields (title, description, target date, context, remaining days).  
  - Import/export functionality for goals, milestones, and tasks (CSV/Excel support).  
  - Persistent user preferences and view configurations using Hive storage.  
  - Clean architecture with domain-driven design (DDD) principles.

- **Portfolio Management** — Manage financial data across investments, liabilities, income, and expenses.  
  *(Status: To Do)*  
  - Track assets and liabilities.  
  - Categorize income and expenses.  
  - Analyze overall financial health with insights and reports.

- **More to add...**  
  Additional modules may include habit analytics, productivity metrics, and other life-tracking tools.

---

## High-Level Architecture (Quick View)

```
App (Flutter)
├── core/                                   ← App-wide base setup (theme, typography, constants, Hive initialization)
│
├── goal_tracker/                           ← Complete module for goal, milestone, and task tracking
│   ├── core/                               ← Module-specific constants, dependency injections, and config
│   ├── data/                               ← Data layer: handles persistence and remote/local data operations
│   │   ├── datasources/                    ← Sources of truth (Hive adapters, REST APIs, CSV import/export handlers)
│   │   ├── models/                         ← Data Transfer Objects (DTOs) and Hive/JSON model definitions
│   │   └── repositories/                   ← Repository implementations bridging domain ↔ data (e.g., GoalRepositoryImpl)
│   ├── domain/                             ← Business logic definitions (pure, framework-independent)
│   │   ├── entities/                       ← Core entities like Goal, Milestone, Task
│   │   ├── repositories/                   ← Abstract repository contracts (e.g., GoalRepository)
│   │   └── usecases/                       ← Reusable domain operations (e.g., AddGoal, GetGoals, UpdateGoalStatus)
│   ├── features/                           ← Self-contained feature logic (e.g., import/export, filtering)
│   └── presentation/                       ← UI layer — Flutter widgets, screens, and state management
│       ├── bloc/                           ← BLoC/Cubit classes for state handling (GoalCubit, MilestoneCubit, TaskCubit)
│       ├── pages/                          ← Screens/pages (HomePage, GoalListPage, MilestoneListPage, TaskListPage, SettingsPage)
│       └── widgets/                        ← Reusable goal-specific widgets (GoalListItem, MilestoneFormBottomSheet, TaskFormBottomSheet)
│
├── portfolio_management/                   ← (Planned) Module for managing investments, liabilities, income & expenses
│   ├── core/                               ← Constants, dependency setup, and configuration for finance module
│   ├── data/                               ← Data models, sources (e.g., CSV importers, APIs, Hive storage)
│   ├── domain/                             ← Entities like Investment, Expense, Income, Liability
│   └── presentation/                       ← Pages and widgets for financial tracking (PortfolioDashboardPage, etc.)
│
├── util/                                   ← Shared utility classes (e.g., date/time helpers, number formatters)
│
├── widgets/                                ← Common reusable widgets used across modules (buttons, dropdowns, date pickers)
│
└── main.dart                               ← App entry point (MaterialApp setup, route config, initial dependency injection)
```

---

## Key Features

- **Complete Goal Management System** with hierarchical structure (Goal → Milestone → Task).
- **Advanced Task Management** with automatic goal assignment and status tracking.
- **Comprehensive Filtering & Sorting** with customizable view fields and persistent preferences.
- **Import/Export Functionality** for goals, milestones, and tasks (CSV/Excel support).
- **Persistent Storage** using Hive with migration support for data compatibility.
- **Clean Architecture** with domain-driven design (DDD) principles.
- **State Management** using BLoC/Cubit pattern for reactive UI updates.
- **Theme Support** with light/dark mode and customizable typography.
- **Planned Portfolio Management** for personal finance tracking.

---

## Requirements

- **Flutter SDK:** 3.10+ (stable channel recommended)
- **Dart SDK:** ^3.8.1 (as specified in pubspec.yaml)
- **Android Studio** or **VS Code** (for dev environment)
- **Platform SDKs:**
  - Android SDK (API 33+ recommended)
  - Xcode (for iOS)
- **Dependencies:** See `pubspec.yaml` for complete list including:
  - `flutter_bloc` for state management
  - `hive_flutter` for local storage
  - `provider` for dependency injection
  - `excel` for import/export functionality
  - `file_picker` and `file_selector` for file operations

---

## Local Setup / Run

1. Clone the repository:
   ```bash
   git clone https://github.com/sachinkhg/all_tracker.git
   cd all_tracker
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. (Optional) Run for specific platforms:
   ```bash
   flutter run -d chrome      # Web
   flutter run -d emulator    # Android emulator
   flutter run -d ios         # iOS
   ```

---

## Running Tests

```bash
flutter test
```

For integration tests (if available):
```bash
flutter test integration_test
```

---

## Linting & Formatting

```bash
flutter analyze
```

---

## Where to Start in Code

- `lib/main.dart` — App entry point with Hive initialization and theme setup.
- `lib/core/` — App-level configurations (theme, typography, Hive setup).
- `lib/goal_tracker/` — Complete goal, milestone, and task management module.
  - `lib/goal_tracker/presentation/pages/home_page.dart` — Main dashboard with navigation.
  - `lib/goal_tracker/domain/entities/` — Core business entities (Goal, Milestone, Task).
  - `lib/goal_tracker/presentation/bloc/` — State management (GoalCubit, MilestoneCubit, TaskCubit).
- `lib/portfolio_management/` — Placeholder for upcoming finance module.
- `lib/util/` — Utility helpers and common functions.
- `lib/widgets/` — Shared UI widgets (buttons, forms, date pickers).

---

## Developer documentation

- `readme/DEVELOPER_REFERENCE.md` — **Models, use cases, and UI components** (with copy/paste examples).
- `migration_notes.md` — Hive **TypeId + box registry** and migration rules.
- `readme/new_model_checklist.md` — Step-by-step checklist for adding a new model end-to-end.

## Key Implementation Details

- **Hierarchical Data Model**: Goal → Milestone → Task with automatic goal assignment for tasks.
- **Clean Architecture**: Domain, Data, and Presentation layers with clear separation of concerns.
- **State Management**: BLoC/Cubit pattern for reactive UI updates.
- **Persistence**: Hive local storage with TypeId registry and migration support.
- **Import/Export**: CSV/Excel support for data portability.
- **Filtering & Views**: Advanced filtering, sorting, and customizable view fields with persistent preferences.

---

## Current Implementation Status

### ✅ Completed Features

- **Goal Management**: Full CRUD operations with Hive persistence
- **Milestone Management**: Complete milestone tracking with goal relationships
- **Task Management**: Advanced task system with automatic goal assignment
- **Import/Export**: CSV/Excel support for all entities (goals, milestones, tasks)
- **Filtering & Sorting**: Advanced filtering by context, date, and completion status
- **View Customization**: Configurable view fields with persistent preferences
- **Theme System**: Light/dark mode support with customizable typography
- **State Management**: Complete BLoC/Cubit implementation for all entities
- **Testing**: Comprehensive unit tests for repositories, cubits, and widgets

### 🚧 In Progress

- **UI/UX Enhancements**: Ongoing improvements to user interface
- **Performance Optimization**: Database query optimization and caching

### 📋 Planned Features

- **Portfolio Management**: Financial tracking module (investments, expenses, income)
- **Analytics Dashboard**: Progress tracking and insights
- **Habit Tracking**: Daily habit monitoring and streak tracking
- **Notifications**: Reminder system for deadlines and milestones

---

## Recent Updates

- **Task Model Implementation**: Complete task management system with automatic goal assignment
- **Advanced Filtering**: Context-based and date-based filtering with persistent preferences
- **Import/Export System**: Full data portability with CSV/Excel support
- **Clean Architecture**: Domain-driven design with proper separation of concerns
- **Comprehensive Testing**: Unit tests for all major components

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines, branching conventions, and test policies.

---

## License

TBD
