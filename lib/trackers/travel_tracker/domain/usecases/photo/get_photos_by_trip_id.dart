import '../../entities/photo.dart';
import '../../repositories/photo_repository.dart';

/// Use case for retrieving all photos for a trip.
class GetPhotosByTripId {
  final PhotoRepository repository;

  GetPhotosByTripId(this.repository);

  Future<List<Photo>> call(String tripId) async => repository.getPhotosByTripId(tripId);
}

