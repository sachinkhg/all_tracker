import '../entities/trip.dart';

/// Abstract repository defining CRUD operations for [Trip] entities.
abstract class TripRepository {
  /// Retrieve all trips from storage.
  Future<List<Trip>> getAllTrips();

  /// Retrieve a single trip by its unique [id].
  /// Returns null if not found.
  Future<Trip?> getTripById(String id);

  /// Create a new [Trip] entry in storage.
  Future<void> createTrip(Trip trip);

  /// Update an existing [Trip].
  Future<void> updateTrip(Trip trip);

  /// Delete the trip identified by [id].
  Future<void> deleteTrip(String id);
}

