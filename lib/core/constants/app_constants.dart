/// App-wide shared constants.
///
/// This file contains constants that are truly shared across multiple modules.
/// Module-specific constants should remain in their respective module's constants.dart files.

/// Hive box names for shared preference boxes.
/// These boxes are used across multiple modules for storing user preferences.

/// Hive box name for view field preferences.
///
/// Stores user preferences for which fields are visible in list views.
/// Keys within this box: 'goal_view', 'milestone_view', 'task_view', etc.
/// Each key maps to a JSON-encoded Map<String, bool> of field visibility settings.
const String viewPreferencesBoxName = 'view_preferences_box';

/// Hive box name for filter preferences.
///
/// Stores user preferences for filter settings across entity types.
/// Keys within this box: 'goal_filters', 'milestone_filters', 'task_filters', etc.
/// Each key maps to a Map<String, String?> of filter key-value pairs.
const String filterPreferencesBoxName = 'filter_preferences_box';

/// Hive box name for sort preferences.
///
/// Stores user preferences for sort settings across entity types.
/// Keys within this box: 'goal_sort', 'milestone_sort', 'task_sort', etc.
/// Each key maps to a Map<String, dynamic> of sort order and hide completed settings.
const String sortPreferencesBoxName = 'sort_preferences_box';

/// Hive box name for theme preferences (color scheme, font, dark mode).
const String themePreferencesBoxName = 'theme_preferences_box';

/// Hive box name for organization preferences (tracker/utility visibility, default home page).
const String organizationPreferencesBoxName = 'organization_preferences_box';

/// Hive box name for backup preferences.
const String backupPreferencesBoxName = 'backup_preferences_box';

