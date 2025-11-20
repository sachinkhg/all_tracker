import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/photo/add_photo.dart';
import '../../domain/usecases/photo/get_photos_by_entry_id.dart';
import '../../domain/usecases/photo/get_photos_by_trip_id.dart';
import '../../domain/usecases/photo/delete_photo.dart';
import '../../data/services/photo_storage_service.dart';
import 'photo_state.dart';

/// Cubit to manage Photo state.
class PhotoCubit extends Cubit<PhotoState> {
  final AddPhoto add;
  final GetPhotosByEntryId getPhotos;
  final GetPhotosByTripId? getPhotosByTrip;
  final DeletePhoto delete;
  final PhotoStorageService storageService;

  static const _uuid = Uuid();

  PhotoCubit({
    required this.add,
    required this.getPhotos,
    this.getPhotosByTrip,
    required this.delete,
    required this.storageService,
  }) : super(PhotosLoading());

  Future<void> loadPhotos(String entryId) async {
    try {
      emit(PhotosLoading());
      final photos = await getPhotos(entryId);
      photos.sort((a, b) {
        final aDate = a.dateTaken ?? a.createdAt;
        final bDate = b.dateTaken ?? b.createdAt;
        return bDate.compareTo(aDate); // Newest first
      });
      emit(PhotosLoaded(photos));
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> loadPhotosForTrip(String tripId) async {
    try {
      if (getPhotosByTrip == null) {
        emit(PhotosError('Trip photos not available'));
        return;
      }
      emit(PhotosLoading());
      final photos = await getPhotosByTrip!(tripId);
      photos.sort((a, b) {
        final aDate = a.dateTaken ?? a.createdAt;
        final bDate = b.dateTaken ?? b.createdAt;
        return bDate.compareTo(aDate); // Newest first
      });
      emit(PhotosLoaded(photos));
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> addPhotoFromPath({
    required String entryId,
    required String sourcePath,
    String? caption,
    DateTime? dateTaken,
    DateTime? taggedDay,
    String? taggedLocation,
  }) async {
    try {
      final photoId = _uuid.v4();
      final savedPath = await storageService.savePhoto(sourcePath, photoId);

      final now = DateTime.now();
      final photo = Photo(
        id: photoId,
        journalEntryId: entryId,
        filePath: savedPath,
        caption: caption,
        dateTaken: dateTaken ?? now,
        taggedDay: taggedDay,
        taggedLocation: taggedLocation,
        createdAt: now,
      );

      await add(photo);
      await loadPhotos(entryId);
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }

  Future<void> deletePhotoById(String id, String entryId) async {
    try {
      // Get photo to delete file
      final photos = (state as PhotosLoaded).photos;
      final photo = photos.firstWhere((p) => p.id == id);
      await storageService.deletePhoto(photo.filePath);

      await delete(id);
      await loadPhotos(entryId);
    } catch (e) {
      emit(PhotosError(e.toString()));
    }
  }
}

