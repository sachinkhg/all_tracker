import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/trip_model.dart';
import '../data/models/trip_profile_model.dart';
import '../data/models/traveler_model.dart';
import '../data/models/itinerary_day_model.dart';
import '../data/models/itinerary_item_model.dart';
import '../data/models/journal_entry_model.dart';
import '../data/models/photo_model.dart';
import '../data/models/expense_model.dart';
import '../core/constants.dart';

/// Hive initializer for the travel_tracker module.
class TravelTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register TripModel adapter (TypeId: 14)
    final tripAdapterId = TripModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(tripAdapterId)) {
      Hive.registerAdapter(TripModelAdapter());
    }

    // Register TripProfileModel adapter (TypeId: 15)
    final tripProfileAdapterId = TripProfileModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(tripProfileAdapterId)) {
      Hive.registerAdapter(TripProfileModelAdapter());
    }

    // Register ItineraryDayModel adapter (TypeId: 16)
    final itineraryDayAdapterId = ItineraryDayModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(itineraryDayAdapterId)) {
      Hive.registerAdapter(ItineraryDayModelAdapter());
    }

    // Register ItineraryItemModel adapter (TypeId: 17)
    final itineraryItemAdapterId = ItineraryItemModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(itineraryItemAdapterId)) {
      Hive.registerAdapter(ItineraryItemModelAdapter());
    }

    // Register JournalEntryModel adapter (TypeId: 18)
    final journalEntryAdapterId = JournalEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(journalEntryAdapterId)) {
      Hive.registerAdapter(JournalEntryModelAdapter());
    }

    // Register PhotoModel adapter (TypeId: 19)
    final photoAdapterId = PhotoModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(photoAdapterId)) {
      Hive.registerAdapter(PhotoModelAdapter());
    }

    // Register ExpenseModel adapter (TypeId: 20)
    final expenseAdapterId = ExpenseModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseAdapterId)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }

    // Register TravelerModel adapter (TypeId: 21)
    final travelerAdapterId = TravelerModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(travelerAdapterId)) {
      Hive.registerAdapter(TravelerModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open travel tracker boxes
    await Hive.openBox<TripModel>(tripBoxName);
    await Hive.openBox<TripProfileModel>(tripProfileBoxName);
    await Hive.openBox<TravelerModel>(travelerBoxName);
    await Hive.openBox<ItineraryDayModel>(itineraryDayBoxName);
    await Hive.openBox<ItineraryItemModel>(itineraryItemBoxName);
    await Hive.openBox<JournalEntryModel>(journalEntryBoxName);
    await Hive.openBox<PhotoModel>(photoBoxName);
    await Hive.openBox<ExpenseModel>(expenseBoxName);
  }
}

