import '../entities/traveler.dart';

/// Abstract repository defining CRUD operations for [Traveler] entities.
abstract class TravelerRepository {
  /// Retrieve all travelers for a trip.
  Future<List<Traveler>> getTravelersByTripId(String tripId);

  /// Retrieve a single traveler by its unique [id].
  /// Returns null if not found.
  Future<Traveler?> getTravelerById(String id);

  /// Create a new [Traveler] entry.
  Future<void> createTraveler(Traveler traveler);

  /// Update an existing [Traveler].
  Future<void> updateTraveler(Traveler traveler);

  /// Delete the traveler identified by [id].
  Future<void> deleteTraveler(String id);
}

