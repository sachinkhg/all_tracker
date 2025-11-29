// lib/core/constants.dart

// Re-export shared constants from app_constants for backward compatibility
export 'package:all_tracker/core/constants/app_constants.dart'
    show
        viewPreferencesBoxName,
        filterPreferencesBoxName,
        sortPreferencesBoxName,
        themePreferencesBoxName,
        organizationPreferencesBoxName,
        backupPreferencesBoxName;

/// ---------------------------------------------------------------------------
/// Goal Tracker Constants
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Constants specific to the goal_tracker module.
/// - Module-level box names and configuration values.
///
/// Cross-module guidance:
/// - Do **not** import feature-level constants from other modules to avoid circular dependencies.
/// - Shared constants are re-exported from app_constants.dart above.
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
const String milestoneBoxName = 'milestones_box';
const String taskBoxName = 'tasks_box';
const String habitBoxName = 'habits_box';
const String habitCompletionBoxName = 'habit_completions_box';
const String backupMetadataBoxName = 'backup_metadata_box';
