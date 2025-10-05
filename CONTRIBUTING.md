# Contributing to all_tracker

Thanks for wanting to contribute! This guide covers how to set up a local dev environment, branch naming, commit style, tests, and creating issues/PRs.

## Development environment setup

1. Install Flutter (stable). Recommended:
   - Flutter SDK (stable) — use `flutter --version` to confirm. Use a stable release >= 3.10 if possible.
2. Install platform tooling:
   - Android: Android SDK & emulator (Android Studio).
   - iOS (macOS): Xcode & simulators.
3. Clone and fetch packages:
   ```bash
   git clone https://github.com/sachinkhg/all_tracker.git
   cd all_tracker
   flutter pub get
   ```
4. Start the app:
   ```bash
   flutter run
   ```

## Branching & work flow

- Use the GitHub Flow:
  - `main` holds the production-ready code.
  - Create feature branches off `main`.
- Branch naming:
  - `feature/<short-description>` — new features
  - `fix/<short-description>` — bug fixes
  - `chore/<short-description>` — housekeeping, dependencies, formatting
  - `test/<short-description>` — tests only
  - Examples: `feature/add-goal-filter`, `fix/fab-layout`, `chore/update-deps`

## Commit message style

Adopt Conventional Commits (short and machine-readable). Format:
```
<type>(scope?): <short summary>
```
- Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`.
- Example: `feat(goal): add import/export support for CSV`

Write longer description in body if needed; reference issue number: `Closes #123`.

## Pull requests

- Open PR from branch -> `main`.
- PR checklist:
  - [ ] Follows branch & commit rules.
  - [ ] Runs `flutter analyze` and `flutter format`.
  - [ ] Tests added or updated (if applicable).
  - [ ] Descriptive PR title and summary of changes.
  - [ ] Screenshots or GIFs for UI changes (if helpful).

## Tests

- Unit tests: `flutter test`
- Widget tests: `flutter test`
- Run all tests before opening a PR:
  ```bash
  flutter test
  ```

## Linting & formatting

- Use `flutter analyze` to run analysis.
- Auto-format with:
  ```bash
  flutter format .
  ```

## Where to create issues

- Use GitHub Issues for bug reports and feature requests.
- Issue template (suggestion):
  - Title: short descriptive title
  - Body:
    - Steps to reproduce
    - Expected behavior
    - Actual behavior
    - Device & environment (Flutter version, OS, device)
    - Attach logs / screenshots if possible

## Coding guidelines & best practices

- Keep domain logic independent from Flutter widgets.
- Favor small, testable functions and classes.
- Add tests for any non-trivial logic or data mapping.
- Keep UI responsive: avoid heavy work on main isolate.

## Contact & support

- For urgent questions, tag repository owner (e.g., `@sachinkhg`) or open a discussion/issue.

Thanks for improving `all_tracker` — contributions are very welcome!
