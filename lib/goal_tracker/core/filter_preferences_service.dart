import 'package:hive_flutter/hive_flutter.dart';
import '../presentation/widgets/filter_group_bottom_sheet.dart';
import 'constants.dart';

/// ---------------------------------------------------------------------------
/// FilterPreferencesService
///
/// File purpose:
/// - Manages persistence of filter preferences for Goals, Milestones, and Tasks.
/// - Similar to ViewPreferencesService but for filter settings.
/// - Stores filter preferences in Hive box for persistence across app sessions.
///
/// Usage:
/// - Save filter preferences when user checks "Save Filter" checkbox
/// - Load saved preferences when cubits initialize
/// - Clear preferences when user unchecks "Save Filter"
///
/// Storage format:
/// - Keys: 'goal_filters', 'milestone_filters', 'task_filters'
/// - Values: Map<String, String?> containing filter key-value pairs
/// ---------------------------------------------------------------------------

class FilterPreferencesService {
  /// Save filter preferences for a specific entity type
  Future<void> saveFilterPreferences(FilterEntityType entityType, Map<String, String?> filters) async {
    try {
      final box = Hive.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.put(key, filters);
    } catch (e) {
      // Handle error silently or log as needed
      print('Error saving filter preferences: $e');
    }
  }

  /// Load saved filter preferences for a specific entity type
  Map<String, String?>? loadFilterPreferences(FilterEntityType entityType) {
    try {
      final box = Hive.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      final saved = box.get(key);
      return saved != null ? Map<String, String?>.from(saved) : null;
    } catch (e) {
      // Handle error silently or log as needed
      print('Error loading filter preferences: $e');
      return null;
    }
  }

  /// Clear filter preferences for a specific entity type
  Future<void> clearFilterPreferences(FilterEntityType entityType) async {
    try {
      final box = Hive.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.delete(key);
    } catch (e) {
      // Handle error silently or log as needed
      print('Error clearing filter preferences: $e');
    }
  }

  /// Get the storage key for a specific entity type
  String _getKeyForEntity(FilterEntityType entityType) {
    switch (entityType) {
      case FilterEntityType.goal:
        return 'goal_filters';
      case FilterEntityType.milestone:
        return 'milestone_filters';
      case FilterEntityType.task:
        return 'task_filters';
      case FilterEntityType.habit:
        return 'habit_filters';
    }
  }
}
