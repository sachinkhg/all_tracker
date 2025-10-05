# all_tracker

A personal **Flutter** app for tracking progress and productivity — across both **personal goals** and **financial portfolios**.  
This repository includes mobile (Android & iOS) and web builds powered by Flutter.

---

## What this project is

**All Tracker** is a modular productivity and finance management platform built with **Flutter**, designed to unify personal goal tracking and portfolio management.

### Current & Planned Modules

- **Goal Management** — Track and manage goals, habits, milestones, and tasks.  
  *(Status: In Progress)*  
  - Create and monitor personal or professional goals.  
  - Define milestones (time- or metric-based) within each goal.  
  - Add and manage tasks under each milestone.  
  - Filter, sort, and toggle view fields (e.g., title, remaining days, target date).  
  - Import/export goal data and persist view preferences.

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
├── goal_management/                        ← Complete module for goal, habit, milestone, and task tracking
│   ├── core/                               ← Module-specific constants, dependency injections, and config
│   ├── data/                               ← Data layer: handles persistence and remote/local data operations
│   │   ├── datasources/                    ← Sources of truth (Hive adapters, REST APIs, CSV import/export handlers)
│   │   ├── models/                         ← Data Transfer Objects (DTOs) and Hive/JSON model definitions
│   │   └── repositories/                   ← Repository implementations bridging domain ↔ data (e.g., GoalRepositoryImpl)
│   ├── domain/                             ← Business logic definitions (pure, framework-independent)
│   │   ├── entities/                       ← Core entities like Goal, Milestone, Task, Context
│   │   ├── repositories/                   ← Abstract repository contracts (e.g., GoalRepository)
│   │   └── usecases/                       ← Reusable domain operations (e.g., AddGoal, GetGoals, UpdateGoalStatus)
│   ├── features/                           ← Self-contained feature logic (e.g., import/export, filtering)
│   └── presentation/                       ← UI layer — Flutter widgets, screens, and state management
│       ├── bloc/                           ← BLoC/Cubit classes for state handling (GoalCubit, GoalState, FilterBloc, etc.)
│       ├── pages/                          ← Screens/pages (GoalListPage, GoalDetailsPage, AddGoalPage)
│       └── widgets/                        ← Reusable goal-specific widgets (GoalListItem, GoalFormBottomSheet)
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

- Modular **goal management system** with milestones and tasks.
- Planned **portfolio management** for personal finance tracking.
- Configurable **view fields and filters**.
- Import/export data support with future-proof migration logic.
- Persistent user preferences using Hive.
- Scalable **clean architecture** (domain / data / presentation separation).

---

## Requirements

- **Flutter SDK:** 3.10+ (stable channel recommended)
- **Dart SDK:** Bundled with Flutter
- **Android Studio** or **VS Code** (for dev environment)
- **Platform SDKs:**
  - Android SDK (API 33+ recommended)
  - Xcode (for iOS)

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

- `lib/main.dart` — App entry point.
- `lib/core/` — App-level configurations.
- `lib/goal_management/` — Main functional module for goals, milestones, and tasks.
- `lib/portfolio_management/` — Placeholder for upcoming finance module.
- `lib/util/` — Utility helpers.
- `lib/widgets/` — Shared UI widgets.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines, branching conventions, and test policies.

---

## License

TBD
