import '../../entities/trip_profile.dart';
import '../../repositories/trip_profile_repository.dart';

/// Use case for retrieving a profile by trip ID.
class GetProfileByTripId {
  final TripProfileRepository repository;

  GetProfileByTripId(this.repository);

  Future<TripProfile?> call(String tripId) async => repository.getProfileByTripId(tripId);
}

