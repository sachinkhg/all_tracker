import '../../entities/trip.dart';
import '../../repositories/trip_repository.dart';

/// Use case for retrieving a trip by ID.
class GetTripById {
  final TripRepository repository;

  GetTripById(this.repository);

  Future<Trip?> call(String id) async => repository.getTripById(id);
}

