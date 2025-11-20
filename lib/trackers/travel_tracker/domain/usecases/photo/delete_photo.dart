import '../../repositories/photo_repository.dart';

/// Use case for deleting a photo.
class DeletePhoto {
  final PhotoRepository repository;

  DeletePhoto(this.repository);

  Future<void> call(String id) async => repository.deletePhoto(id);
}

