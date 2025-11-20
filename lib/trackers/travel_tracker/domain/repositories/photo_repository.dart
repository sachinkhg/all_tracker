import '../entities/photo.dart';

/// Abstract repository defining CRUD operations for [Photo] entities.
abstract class PhotoRepository {
  /// Get all photos for a journal entry.
  Future<List<Photo>> getPhotosByEntryId(String entryId);

  /// Get all photos for a trip.
  Future<List<Photo>> getPhotosByTripId(String tripId);

  /// Get a photo by ID.
  Future<Photo?> getPhotoById(String id);

  /// Add a new photo.
  Future<void> addPhoto(Photo photo);

  /// Update an existing photo.
  Future<void> updatePhoto(Photo photo);

  /// Delete a photo.
  Future<void> deletePhoto(String id);
}

