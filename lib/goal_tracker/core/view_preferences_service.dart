import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../goal_tracker/presentation/widgets/view_field_bottom_sheet.dart';
import 'constants.dart';

/// ---------------------------------------------------------------------------
/// ViewPreferencesService
///
/// File purpose:
/// - Provides a centralized service for persisting and retrieving user view
///   field preferences across app sessions.
/// - Manages which fields are visible for each entity type (Goal, Milestone, Task).
///
/// Storage strategy:
/// - Uses a dedicated Hive box (view_preferences_box) to store preferences.
/// - Each entity type has its own key: 'goal_view', 'milestone_view', 'task_view'
/// - Values are JSON-encoded Map<String, bool> structures representing field visibility.
///
/// Compatibility guidance:
/// - All methods handle null/missing data gracefully with proper fallbacks.
/// - If no saved preferences exist, returns null to let callers use their defaults.
/// - JSON encoding ensures easy serialization and compatibility with Hive's dynamic storage.
///
/// Developer notes:
/// - This is a stateless service class; all state lives in Hive.
/// - Methods are synchronous for reads (Hive is fast) and async for writes.
/// - Keep this service simple and focused on persistence only; business logic
///   belongs in cubits or use cases.
/// ---------------------------------------------------------------------------

class ViewPreferencesService {
  /// Loads saved view preferences for a given entity type.
  ///
  /// Returns:
  /// - Map<String, bool> if preferences are found and valid
  /// - null if no preferences are saved or if decoding fails
  ///
  /// This allows the caller to fall back to their own defaults when null is returned.
  Map<String, bool>? loadViewPreferences(ViewEntityType entity) {
    try {
      final box = Hive.box(viewPreferencesBoxName);
      final key = _keyForEntity(entity);
      final jsonString = box.get(key) as String?;
      
      if (jsonString == null) {
        return null;
      }
      
      // Decode JSON and convert to Map<String, bool>
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as bool));
    } catch (e) {
      // If decoding fails or box is unavailable, return null to use defaults
      return null;
    }
  }

  /// Saves view preferences for a given entity type.
  ///
  /// Parameters:
  /// - entity: The entity type (goal, milestone, or task)
  /// - fields: Map of field names to visibility booleans
  ///
  /// The fields map is JSON-encoded and stored in the Hive box with an entity-specific key.
  Future<void> saveViewPreferences(
    ViewEntityType entity,
    Map<String, bool> fields,
  ) async {
    try {
      final box = Hive.box(viewPreferencesBoxName);
      final key = _keyForEntity(entity);
      final jsonString = jsonEncode(fields);
      await box.put(key, jsonString);
    } catch (e) {
      // Silently fail if save operation encounters an error.
      // In production, consider logging this error to a monitoring service.
    }
  }

  /// Clears (deletes) saved view preferences for a given entity type.
  ///
  /// This is called when the user unchecks "Save View" and applies changes,
  /// indicating they want to reset to defaults on the next app launch.
  Future<void> clearViewPreferences(ViewEntityType entity) async {
    try {
      final box = Hive.box(viewPreferencesBoxName);
      final key = _keyForEntity(entity);
      await box.delete(key);
    } catch (e) {
      // Silently fail if delete operation encounters an error.
    }
  }

  /// Maps a ViewEntityType to its corresponding storage key.
  ///
  /// These keys are the canonical identifiers used in the Hive box.
  /// Changing these keys will lose existing user preferences, so keep them stable.
  String _keyForEntity(ViewEntityType entity) {
    switch (entity) {
      case ViewEntityType.goal:
        return 'goal_view';
      case ViewEntityType.milestone:
        return 'milestone_view';
      case ViewEntityType.task:
        return 'task_view';
      case ViewEntityType.habit:
        return 'habit_view';
    }
  }
}

