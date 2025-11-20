import '../../entities/trip.dart';
import '../../repositories/trip_repository.dart';

/// Use case for creating a new trip.
class CreateTrip {
  final TripRepository repository;

  CreateTrip(this.repository);

  Future<void> call(Trip trip) async => repository.createTrip(trip);
}

