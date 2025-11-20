import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_local_data_source.dart';
import '../datasources/journal_local_data_source.dart';
import '../models/photo_model.dart';

/// Concrete implementation of PhotoRepository.
class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoLocalDataSource local;
  final JournalLocalDataSource journalLocal;

  PhotoRepositoryImpl({
    required this.local,
    required this.journalLocal,
  });

  @override
  Future<void> addPhoto(Photo photo) async {
    final model = PhotoModel.fromEntity(photo);
    await local.addPhoto(model);
  }

  @override
  Future<void> deletePhoto(String id) async {
    await local.deletePhoto(id);
  }

  @override
  Future<Photo?> getPhotoById(String id) async {
    final model = await local.getPhotoById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Photo>> getPhotosByEntryId(String entryId) async {
    final models = await local.getPhotosByEntryId(entryId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Photo>> getPhotosByTripId(String tripId) async {
    // Get all journal entries for the trip, then get photos for each entry
    final entries = await journalLocal.getEntriesByTripId(tripId);
    final allPhotos = <PhotoModel>[];
    for (final entry in entries) {
      final photos = await local.getPhotosByEntryId(entry.id);
      allPhotos.addAll(photos);
    }
    return allPhotos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updatePhoto(Photo photo) async {
    final model = PhotoModel.fromEntity(photo);
    await local.updatePhoto(model);
  }
}

