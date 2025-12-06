import 'package:equatable/equatable.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';

/// Base state for file operations.
abstract class FileState extends Equatable {
  const FileState();

  @override
  List<Object?> get props => [];
}

/// Loading state - emitted when files are being fetched.
class FilesLoading extends FileState {}

/// Loaded state - holds the list of successfully fetched files.
class FilesLoaded extends FileState {
  final List<CloudFile> files;
  final FileServerConfig? config;
  final String currentPath;

  const FilesLoaded(this.files, {this.config, this.currentPath = '/'});

  @override
  List<Object?> get props => [files, config, currentPath];
}

/// Error state - emitted when fetching files fails.
class FilesError extends FileState {
  final String message;

  const FilesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Initial state - no config set, no files loaded.
class FilesInitial extends FileState {}

