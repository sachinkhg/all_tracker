import 'package:hive/hive.dart';
import '../models/photo_model.dart';

/// Abstract data source for local photo storage.
abstract class PhotoLocalDataSource {
  Future<List<PhotoModel>> getPhotosByEntryId(String entryId);
  Future<List<PhotoModel>> getPhotosByTripId(String tripId);
  Future<PhotoModel?> getPhotoById(String id);
  Future<void> addPhoto(PhotoModel photo);
  Future<void> updatePhoto(PhotoModel photo);
  Future<void> deletePhoto(String id);
}

/// Hive implementation of PhotoLocalDataSource.
class PhotoLocalDataSourceImpl implements PhotoLocalDataSource {
  final Box<PhotoModel> box;

  PhotoLocalDataSourceImpl(this.box);

  @override
  Future<void> addPhoto(PhotoModel photo) async {
    await box.put(photo.id, photo);
  }

  @override
  Future<void> deletePhoto(String id) async {
    await box.delete(id);
  }

  @override
  Future<PhotoModel?> getPhotoById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<PhotoModel>> getPhotosByEntryId(String entryId) async {
    return box.values.where((photo) => photo.journalEntryId == entryId).toList();
  }

  @override
  Future<List<PhotoModel>> getPhotosByTripId(String tripId) async {
    // Note: This requires access to journal entries to find photos.
    // For now, return empty - this will be handled at repository level.
    return [];
  }

  @override
  Future<void> updatePhoto(PhotoModel photo) async {
    await box.put(photo.id, photo);
  }
}

