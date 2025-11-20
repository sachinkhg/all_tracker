import '../../entities/trip.dart';
import '../../repositories/trip_repository.dart';

/// Use case for updating a trip.
class UpdateTrip {
  final TripRepository repository;

  UpdateTrip(this.repository);

  Future<void> call(Trip trip) async => repository.updateTrip(trip);
}

