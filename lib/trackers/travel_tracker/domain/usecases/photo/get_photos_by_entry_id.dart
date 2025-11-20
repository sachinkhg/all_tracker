import '../../entities/photo.dart';
import '../../repositories/photo_repository.dart';

/// Use case for retrieving all photos for a journal entry.
class GetPhotosByEntryId {
  final PhotoRepository repository;

  GetPhotosByEntryId(this.repository);

  Future<List<Photo>> call(String entryId) async => repository.getPhotosByEntryId(entryId);
}

