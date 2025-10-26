# Mocked E2E Test Suite (Layered)

## Scope & assumptions

- Mock Hive and external plugins; no real FS/platform channels.
- Layered coverage: unit (data/domain/services), widget (UI), integration-style flows with fakes.

## Dev dependencies to add (pubspec.yaml)

- mocktail, bloc_test, golden_toolkit, flutter_test, flutter_bloc (test helpers), fake_async

## Test harness and utilities (new files)

- `test/helpers/fake_hive_box.dart`: in-memory `Box<T>` fake (put/get/delete/values/keys/clear).
- `test/helpers/mocks.dart`: simple stubs (or mocktail mocks when desired).
- `test/helpers/test_data.dart`: entity builders with deterministic IDs/dates.
- `test/helpers/platform_stubs.dart`: stub method channel `app.channel.savefile` and plugin surfaces.

## Optional small refactors

- Introduce `BoxProvider` seam for services using `Hive.box(...)`.
- Extract pure mappers from import/export and backup/restore for logic-only tests.
- Allow injecting `Uuid` in cubits/usecases for deterministic IDs.

## Unit tests (data layer)

- Datasources: goal/milestone/task/habit/habit_completion (CRUD + filters).
- Repositories: mapping + delegation to datasources.

## Unit tests (domain layer)

- Usecases: thin delegation checks.
- `ToggleCompletionForDate`: create/delete completion and +/- milestone.actualValue by contribution.

## Unit tests (services)

- View/Filter/Sort/Theme preferences via `BoxProvider` seam using `FakeBox`.

## Widget tests (presentation)

- Provide cubits via `BlocProvider`, verify loading/empty/error/loaded states and interactions.

## Golden tests (key UIs)

- DeviceBuilder goldens for list items/pages under light/dark and sizes.

## Integration-style flow tests (mocked storage)

- Real cubits + real repos over `FakeBox`; drive minimal UIs.
  - Goal CRUD
  - Milestone→Task linking
  - Habit completion progress affecting milestone

## Import/Export & Backup/Restore tests (logic-only)

- Test pure mappers for JSON/XLSX rows; date/context/status normalization.

## Coverage & commands

- Run: `flutter test --coverage`
- Optional: `genhtml coverage/lcov.info -o coverage/html`
- Aim: ≥90% domain/data/cubits; ≥80% features/services.

## CI (optional)

- GH Action to run tests, upload lcov, and golden diffs on PRs.

---

## To-dos

- [x] Add mocktail, bloc_test, golden_toolkit, fake_async to dev_dependencies
- [x] Create FakeBox, mocks, test data, and platform stubs under test/helpers
- [x] Write datasource + repository unit tests using FakeBox for all entities
- [x] Write usecase tests incl. ToggleCompletionForDate behavior
- [ ] Refactor BoxProvider seam; test preference services with FakeBox
- [ ] Write widget tests for pages with mocked cubits; verify states/interactions
- [ ] Add golden tests for list items/pages across themes/sizes
- [ ] Build mocked-storage integration tests for goal/milestone/task/habit flows
- [ ] Extract pure mappers; test import/export and backup/restore logic
- [ ] Add coverage command and (optional) CI job to enforce thresholds
