// lib/trackers/file_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import '../data/datasources/file_remote_data_source.dart';
import '../data/repositories/file_repository_impl.dart';
import '../domain/usecases/get_files.dart';
import '../domain/usecases/get_files_by_type.dart';
import '../domain/usecases/get_files_by_folder.dart';
import '../domain/usecases/search_files.dart';
import '../presentation/bloc/file_cubit.dart';

/// Factory that constructs a fully-wired [FileCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - All objects created here are plain Dart instances (no DI container used).
FileCubit createFileCubit() {
  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final remoteDataSource = FileRemoteDataSource();

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = FileRepositoryImpl(remoteDataSource);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getFiles = GetFiles(repo);
  final getFilesByType = GetFilesByType(repo);
  final getFilesByFolder = GetFilesByFolder(repo);
  final searchFiles = SearchFiles(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return FileCubit(
    getFiles: getFiles,
    getFilesByType: getFilesByType,
    getFilesByFolder: getFilesByFolder,
    searchFiles: searchFiles,
  );
}

