import 'package:hive_flutter/hive_flutter.dart';

// Data sources
import '../data/datasources/trip_local_data_source.dart';
import '../data/datasources/trip_profile_local_data_source.dart';
import '../data/datasources/traveler_local_data_source.dart';
import '../data/datasources/itinerary_local_data_source.dart';
import '../data/datasources/journal_local_data_source.dart';
import '../data/datasources/photo_local_data_source.dart';
import '../data/datasources/expense_local_data_source.dart';

// Models
import '../data/models/trip_model.dart';
import '../data/models/trip_profile_model.dart';
import '../data/models/traveler_model.dart';
import '../data/models/itinerary_day_model.dart';
import '../data/models/itinerary_item_model.dart';
import '../data/models/journal_entry_model.dart';
import '../data/models/photo_model.dart';
import '../data/models/expense_model.dart';

// Repositories
import '../data/repositories/trip_repository_impl.dart';
import '../data/repositories/trip_profile_repository_impl.dart';
import '../data/repositories/traveler_repository_impl.dart';
import '../data/repositories/itinerary_repository_impl.dart';
import '../data/repositories/journal_repository_impl.dart';
import '../data/repositories/photo_repository_impl.dart';
import '../data/repositories/expense_repository_impl.dart';

// Use cases
import '../domain/usecases/trip/create_trip.dart';
import '../domain/usecases/trip/get_all_trips.dart';
import '../domain/usecases/trip/get_trip_by_id.dart';
import '../domain/usecases/trip/update_trip.dart';
import '../domain/usecases/trip/delete_trip.dart';
import '../domain/usecases/itinerary/create_itinerary_day.dart';
import '../domain/usecases/itinerary/get_days_by_trip_id.dart';
import '../domain/usecases/itinerary/update_itinerary_day.dart';
import '../domain/usecases/itinerary/delete_itinerary_day.dart';
import '../domain/usecases/itinerary/create_itinerary_item.dart';
import '../domain/usecases/itinerary/get_items_by_day_id.dart';
import '../domain/usecases/itinerary/update_itinerary_item.dart';
import '../domain/usecases/itinerary/delete_itinerary_item.dart';
import '../domain/usecases/journal/create_journal_entry.dart';
import '../domain/usecases/journal/get_entries_by_trip_id.dart';
import '../domain/usecases/journal/update_journal_entry.dart';
import '../domain/usecases/journal/delete_journal_entry.dart';
import '../domain/usecases/traveler/create_traveler.dart';
import '../domain/usecases/traveler/get_travelers_by_trip_id.dart';
import '../domain/usecases/traveler/update_traveler.dart';
import '../domain/usecases/traveler/delete_traveler.dart';
import '../domain/usecases/photo/add_photo.dart';
import '../domain/usecases/photo/get_photos_by_entry_id.dart';
import '../domain/usecases/photo/get_photos_by_trip_id.dart';
import '../domain/usecases/photo/delete_photo.dart';
import '../domain/usecases/expense/create_expense.dart';
import '../domain/usecases/expense/get_expenses_by_trip_id.dart';
import '../domain/usecases/expense/update_expense.dart';
import '../domain/usecases/expense/delete_expense.dart';

// Cubits
import '../presentation/bloc/trip_cubit.dart';
import '../presentation/bloc/itinerary_cubit.dart';
import '../presentation/bloc/journal_cubit.dart';
import '../presentation/bloc/traveler_cubit.dart';
import '../presentation/bloc/photo_cubit.dart';
import '../presentation/bloc/expense_cubit.dart';

// Services
import '../data/services/photo_storage_service.dart';
import '../../goal_tracker/core/view_preferences_service.dart';
import '../../goal_tracker/core/filter_preferences_service.dart';

// Constants
import 'constants.dart';

/// Factory that constructs a fully-wired TripCubit.
TripCubit createTripCubit() {
  final Box<TripModel> tripBox = Hive.box<TripModel>(tripBoxName);

  // Data layer
  final tripLocal = TripLocalDataSourceImpl(tripBox);

  // Repository layer
  final tripRepo = TripRepositoryImpl(tripLocal);

  // Use cases
  final getAllTrips = GetAllTrips(tripRepo);
  final createTrip = CreateTrip(tripRepo);
  final updateTrip = UpdateTrip(tripRepo);
  final deleteTrip = DeleteTrip(tripRepo);
  final getTripById = GetTripById(tripRepo);

  // Services
  final viewPreferencesService = ViewPreferencesService();
  final filterPreferencesService = FilterPreferencesService();

  // Presentation
  return TripCubit(
    getAll: getAllTrips,
    create: createTrip,
    update: updateTrip,
    delete: deleteTrip,
    getById: getTripById,
    viewPreferencesService: viewPreferencesService,
    filterPreferencesService: filterPreferencesService,
  );
}

/// Factory that constructs a fully-wired TripProfileRepository.
TripProfileRepositoryImpl createTripProfileRepository() {
  final Box<TripProfileModel> profileBox =
      Hive.box<TripProfileModel>(tripProfileBoxName);

  final profileLocal = TripProfileLocalDataSourceImpl(profileBox);
  return TripProfileRepositoryImpl(profileLocal);
}

/// Factory that constructs a fully-wired ItineraryCubit.
ItineraryCubit createItineraryCubit() {
  final Box<ItineraryDayModel> dayBox =
      Hive.box<ItineraryDayModel>(itineraryDayBoxName);
  final Box<ItineraryItemModel> itemBox =
      Hive.box<ItineraryItemModel>(itineraryItemBoxName);
  final Box<TripModel> tripBox = Hive.box<TripModel>(tripBoxName);

  // Data layer
  final itineraryLocal = ItineraryLocalDataSourceImpl(
    dayBox: dayBox,
    itemBox: itemBox,
  );
  final tripLocal = TripLocalDataSourceImpl(tripBox);

  // Repository layer
  final itineraryRepo = ItineraryRepositoryImpl(itineraryLocal);
  final tripRepo = TripRepositoryImpl(tripLocal);

  // Use cases
  final createDay = CreateItineraryDay(itineraryRepo);
  final getDays = GetDaysByTripId(itineraryRepo);
  final updateDay = UpdateItineraryDay(itineraryRepo);
  final deleteDay = DeleteItineraryDay(itineraryRepo);
  final createItem = CreateItineraryItem(itineraryRepo);
  final getItems = GetItemsByDayId(itineraryRepo);
  final updateItem = UpdateItineraryItem(itineraryRepo);
  final deleteItem = DeleteItineraryItem(itineraryRepo);
  final getTripById = GetTripById(tripRepo);

  // Services
  final viewPreferencesService = ViewPreferencesService();
  final filterPreferencesService = FilterPreferencesService();

  // Presentation
  return ItineraryCubit(
    createDay: createDay,
    getDays: getDays,
    updateDay: updateDay,
    deleteDay: deleteDay,
    createItem: createItem,
    getItems: getItems,
    updateItem: updateItem,
    deleteItem: deleteItem,
    getTripById: getTripById,
    viewPreferencesService: viewPreferencesService,
    filterPreferencesService: filterPreferencesService,
  );
}

/// Factory that constructs a fully-wired JournalCubit.
JournalCubit createJournalCubit() {
  final Box<JournalEntryModel> entryBox =
      Hive.box<JournalEntryModel>(journalEntryBoxName);

  // Data layer
  final journalLocal = JournalLocalDataSourceImpl(entryBox);

  // Repository layer
  final journalRepo = JournalRepositoryImpl(journalLocal);

  // Use cases
  final create = CreateJournalEntry(journalRepo);
  final getEntries = GetEntriesByTripId(journalRepo);
  final update = UpdateJournalEntry(journalRepo);
  final delete = DeleteJournalEntry(journalRepo);

  // Presentation
  return JournalCubit(
    create: create,
    getEntries: getEntries,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired PhotoCubit.
PhotoCubit createPhotoCubit() {
  final Box<PhotoModel> photoBox = Hive.box<PhotoModel>(photoBoxName);
  final Box<JournalEntryModel> entryBox =
      Hive.box<JournalEntryModel>(journalEntryBoxName);

  // Data layer
  final photoLocal = PhotoLocalDataSourceImpl(photoBox);
  final journalLocal = JournalLocalDataSourceImpl(entryBox);

  // Repository layer
  final photoRepo = PhotoRepositoryImpl(
    local: photoLocal,
    journalLocal: journalLocal,
  );

  // Use cases
  final add = AddPhoto(photoRepo);
  final getPhotos = GetPhotosByEntryId(photoRepo);
  final getPhotosByTrip = GetPhotosByTripId(photoRepo);
  final delete = DeletePhoto(photoRepo);

  // Services
  final storageService = PhotoStorageService();

  // Presentation
  return PhotoCubit(
    add: add,
    getPhotos: getPhotos,
    getPhotosByTrip: getPhotosByTrip,
    delete: delete,
    storageService: storageService,
  );
}

/// Factory that constructs a fully-wired ExpenseCubit.
ExpenseCubit createExpenseCubit() {
  final Box<ExpenseModel> expenseBox =
      Hive.box<ExpenseModel>(expenseBoxName);

  // Data layer
  final expenseLocal = ExpenseLocalDataSourceImpl(expenseBox);

  // Repository layer
  final expenseRepo = ExpenseRepositoryImpl(expenseLocal);

  // Use cases
  final create = CreateExpense(expenseRepo);
  final getExpenses = GetExpensesByTripId(expenseRepo);
  final update = UpdateExpense(expenseRepo);
  final delete = DeleteExpense(expenseRepo);

  // Presentation
  return ExpenseCubit(
    create: create,
    getExpenses: getExpenses,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired TravelerCubit.
TravelerCubit createTravelerCubit() {
  final Box<TravelerModel> travelerBox =
      Hive.box<TravelerModel>(travelerBoxName);

  // Data layer
  final travelerLocal = TravelerLocalDataSourceImpl(travelerBox);

  // Repository layer
  final travelerRepo = TravelerRepositoryImpl(travelerLocal);

  // Use cases
  final create = CreateTraveler(travelerRepo);
  final getTravelers = GetTravelersByTripId(travelerRepo);
  final update = UpdateTraveler(travelerRepo);
  final delete = DeleteTraveler(travelerRepo);

  // Presentation
  return TravelerCubit(
    create: create,
    getTravelers: getTravelers,
    update: update,
    delete: delete,
  );
}

