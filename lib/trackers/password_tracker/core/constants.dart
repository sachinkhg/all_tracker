// lib/trackers/password_tracker/core/constants.dart

/// ---------------------------------------------------------------------------
/// Password Tracker Constants
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Constants specific to the password_tracker module.
/// - Module-level box names and configuration values.
///
/// Cross-module guidance:
/// - Do **not** import feature-level constants from other modules to avoid circular dependencies.
/// - Shared constants are re-exported from app_constants.dart if needed.
/// ---------------------------------------------------------------------------

/// Hive box name for password persistence.
///
/// - Keep this name stable across app versions to avoid data loss or migration overhead.
/// - The box name is referenced in both `HiveInitializer` and repository/data source wiring.
const String passwordBoxName = 'passwords_box';

/// Hive box name for secret question persistence.
///
/// - Keep this name stable across app versions to avoid data loss or migration overhead.
/// - The box name is referenced in both `HiveInitializer` and repository/data source wiring.
const String secretQuestionBoxName = 'secret_questions_box';

