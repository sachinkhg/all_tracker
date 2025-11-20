import '../../repositories/trip_repository.dart';

/// Use case for deleting a trip.
class DeleteTrip {
  final TripRepository repository;

  DeleteTrip(this.repository);

  Future<void> call(String id) async => repository.deleteTrip(id);
}

