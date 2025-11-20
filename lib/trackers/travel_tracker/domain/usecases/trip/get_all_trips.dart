import '../../entities/trip.dart';
import '../../repositories/trip_repository.dart';

/// Use case for retrieving all trips.
class GetAllTrips {
  final TripRepository repository;

  GetAllTrips(this.repository);

  Future<List<Trip>> call() async => repository.getAllTrips();
}

