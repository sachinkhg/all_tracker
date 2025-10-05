// // lib/data/migration_manager.dart
// import 'package:flutter/foundation.dart';
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// typedef MigrationFn = Future<void> Function();

// class Migration {
//   final int version;
//   final String name;
//   final MigrationFn run;

//   Migration({required this.version, required this.name, required this.run});
// }

// /// A simple migration manager for Hive-based apps.
// /// - Keeps applied versions in a persistent box named 'app_migrations_meta'
// /// - Exposes a boolean flag 'migrations_enabled' in the same box to allow toggling migrations
// /// - Call registerMigration(...) for each migration (in increasing version order)
// /// - Call runPendingMigrations() once on startup (after Hive.initFlutter() and after registering any compat adapters)
// class MigrationManager {
//   static const String _metaBoxName = 'app_migrations_meta';
//   static const String _appliedKey = 'applied_versions'; // stored as List<int>
//   static const String _enabledKey = 'migrations_enabled';

//   final List<Migration> _migrations = [];

//   /// Register a migration. Version should be strictly increasing for new migrations.
//   void registerMigration(int version, String name, MigrationFn fn) {
//     if (_migrations.any((m) => m.version == version)) {
//       throw ArgumentError('Migration with version $version already registered.');
//     }
//     _migrations.add(Migration(version: version, name: name, run: fn));
//     // sort by version just in case
//     _migrations.sort((a, b) => a.version.compareTo(b.version));
//   }

//   /// Returns true if migrations are enabled (persistent flag). Defaults to true if absent.
//   Future<bool> migrationsEnabled() async {
//     final box = await Hive.openBox(_metaBoxName);
//     final v = box.get(_enabledKey);
//     await box.close();
//     if (v == null) return true;
//     return v as bool;
//   }

//   /// Set persistent flag to enable/disable migrations.
//   Future<void> setMigrationsEnabled(bool enabled) async {
//     final box = await Hive.openBox(_metaBoxName);
//     await box.put(_enabledKey, enabled);
//     await box.close();
//   }

//   /// Run pending migrations.
//   ///
//   /// - If [force] == true, run migrations even if they are already marked applied.
//   /// - NOTE: Call this after you registered any compatibility adapters required to safely open boxes.
//   Future<void> runPendingMigrations({bool force = false}) async {
//     final metaBox = await Hive.openBox(_metaBoxName);

//     final bool enabled = metaBox.get(_enabledKey, defaultValue: true) as bool;
//     if (!enabled && !force) {
//       debugPrint('Migrations disabled (persistent flag). Skipping migrations.');
//       await metaBox.close();
//       return;
//     }

//     final List<dynamic> appliedRaw = metaBox.get(_appliedKey, defaultValue: <dynamic>[]) as List<dynamic>;
//     final Set<int> applied = appliedRaw.map((e) => e as int).toSet();

//     debugPrint('MigrationManager: applied versions: $applied');

//     for (final m in _migrations) {
//       if (!force && applied.contains(m.version)) {
//         debugPrint('MigrationManager: skipping version ${m.version} (${m.name}) — already applied.');
//         continue;
//       }

//       try {
//         debugPrint('MigrationManager: running version ${m.version} (${m.name})...');
//         await m.run();
//         // mark applied
//         applied.add(m.version);
//         await metaBox.put(_appliedKey, applied.toList());
//         debugPrint('MigrationManager: completed version ${m.version}.');
//       } catch (e, st) {
//         debugPrint('MigrationManager: migration ${m.version} failed: $e\n$st');
//         // You can choose to rethrow to block app startup, or continue.
//         // For safety we rethrow to ensure developer notices migration failure.
//         await metaBox.close();
//         rethrow;
//       }
//     }

//     await metaBox.close();
//     debugPrint('MigrationManager: all migrations processed.');
//   }

//   /// helper: get list of registered migration versions (for debugging)
//   List<int> registeredVersions() => _migrations.map((m) => m.version).toList();
// }
