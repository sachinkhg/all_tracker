import '../../repositories/traveler_repository.dart';

/// Use case for deleting a traveler.
class DeleteTraveler {
  final TravelerRepository repository;

  DeleteTraveler(this.repository);

  Future<void> call(String id) async => repository.deleteTraveler(id);
}

