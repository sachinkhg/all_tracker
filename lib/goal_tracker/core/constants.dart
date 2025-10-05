// lib/core/constants.dart

/// ---------------------------------------------------------------------------
/// App-wide Constants and Design Tokens
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Acts as a single source of truth for immutable values shared across features.
/// - Ensures consistency across modules and prevents "magic strings" or numbers
///   from being duplicated in different layers.
///
/// Organization:
/// - **Configuration constants**: environment-dependent (e.g., API URLs, timeouts) — keep them isolated in
///   an environment file (not here).
/// - **Design tokens / domain constants**: stable identifiers, option lists, or box names used across modules.
///   Those belong here to promote uniformity.
///
/// Cross-module guidance:
/// - Do **not** import feature-level constants (e.g., `goal_tracker/constants.dart`) into this file to avoid circular dependencies.
///   Instead, define shared tokens here and let modules extend them locally.
///
/// Maintenance note:
/// - Treat this file as a foundation. Any value here affects multiple modules — update cautiously and document reasons.
/// - When removing or renaming constants, check for usages in repositories, data sources, and UI widgets.
/// ---------------------------------------------------------------------------

/// Context categories used across goal creation and filtering screens.
///
/// - Acts as a canonical list of user goal contexts.
/// - UI dropdowns and filters should reference this list to stay consistent.
/// - If extending with new contexts, prefer appending at the end to preserve
///   existing order (helps maintain sort stability in Hive-stored data).
const List<String> kContextOptions = [
  'Work',
  'Personal',
  'Health',
  'Finance',
];

/// Hive box name for goal persistence.
///
/// - Keep this name stable across app versions to avoid data loss or migration overhead.
/// - The box name is referenced in both `HiveInitializer` and repository/data source wiring.
/// - Avoid prefixing with module name unless multiple feature boxes exist; use a clear,
///   lowercase underscore format (`feature_data_box`) for new boxes.
const String goalBoxName = 'goals_box';
