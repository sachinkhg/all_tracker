import 'package:equatable/equatable.dart';
import '../../domain/entities/photo.dart';

/// Base state for photo operations.
abstract class PhotoState extends Equatable {
  const PhotoState();

  @override
  List<Object?> get props => [];
}

/// Loading state.
class PhotosLoading extends PhotoState {}

/// Loaded state with photos.
class PhotosLoaded extends PhotoState {
  final List<Photo> photos;

  const PhotosLoaded(this.photos);

  @override
  List<Object?> get props => [photos];
}

/// Error state.
class PhotosError extends PhotoState {
  final String message;

  const PhotosError(this.message);

  @override
  List<Object?> get props => [message];
}

