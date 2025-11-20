import '../../entities/photo.dart';
import '../../repositories/photo_repository.dart';

/// Use case for adding a photo.
class AddPhoto {
  final PhotoRepository repository;

  AddPhoto(this.repository);

  Future<void> call(Photo photo) async => repository.addPhoto(photo);
}

