import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/book_model.dart';
import '../data/models/read_history_entry_model.dart';
import 'constants.dart';

/// Hive initializer for the book_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the book_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class BookTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register ReadHistoryEntryModel adapter (TypeId: 33)
    final readHistoryAdapterId = ReadHistoryEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(readHistoryAdapterId)) {
      Hive.registerAdapter(ReadHistoryEntryModelAdapter());
    }

    // Register BookModel adapter (TypeId: 32)
    final bookAdapterId = BookModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(bookAdapterId)) {
      Hive.registerAdapter(BookModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open book tracker box
    await Hive.openBox<BookModel>(booksTrackerBoxName);
  }
}

