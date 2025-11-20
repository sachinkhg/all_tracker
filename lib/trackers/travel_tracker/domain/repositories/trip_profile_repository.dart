import '../entities/trip_profile.dart';

/// Abstract repository defining CRUD operations for [TripProfile] entities.
abstract class TripProfileRepository {
  /// Retrieve profile by trip ID (one-to-one relationship).
  Future<TripProfile?> getProfileByTripId(String tripId);

  /// Create a new [TripProfile] entry.
  Future<void> createProfile(TripProfile profile);

  /// Update an existing [TripProfile].
  Future<void> updateProfile(TripProfile profile);

  /// Delete profile by trip ID.
  Future<void> deleteProfileByTripId(String tripId);
}

