import '../../entities/itinerary_day.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for retrieving all days for a trip.
class GetDaysByTripId {
  final ItineraryRepository repository;

  GetDaysByTripId(this.repository);

  Future<List<ItineraryDay>> call(String tripId) async => repository.getDaysByTripId(tripId);
}

