/// Interface for module-specific Hive initialization.
///
/// Each module that uses Hive should implement this interface to register
/// its own adapters and open its own boxes. This allows modules to be
/// self-contained and the central HiveInitializer to discover and call
/// all module initializers.
///
/// Usage:
/// ```dart
/// class GoalTrackerHiveInitializer implements HiveModuleInitializer {
///   @override
///   Future<void> registerAdapters() async {
///     if (!Hive.isAdapterRegistered(0)) {
///       Hive.registerAdapter(GoalModelAdapter());
///     }
///     // ... register other adapters
///   }
///
///   @override
///   Future<void> openBoxes() async {
///     await Hive.openBox<GoalModel>(goalBoxName);
///     // ... open other boxes
///   }
/// }
/// ```
abstract class HiveModuleInitializer {
  /// Registers all Hive adapters for this module.
  ///
  /// This method should check if adapters are already registered before
  /// registering them to avoid duplicate registration errors.
  Future<void> registerAdapters();

  /// Opens all Hive boxes required by this module.
  ///
  /// This method should open all boxes that this module needs.
  /// Box names should be defined in the module's constants file.
  Future<void> openBoxes();
}

