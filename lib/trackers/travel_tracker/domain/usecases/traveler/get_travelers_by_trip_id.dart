import '../../entities/traveler.dart';
import '../../repositories/traveler_repository.dart';

/// Use case for retrieving all travelers for a trip.
class GetTravelersByTripId {
  final TravelerRepository repository;

  GetTravelersByTripId(this.repository);

  Future<List<Traveler>> call(String tripId) async => repository.getTravelersByTripId(tripId);
}

