import 'package:equatable/equatable.dart';

/// Domain entity representing the configuration for a file server.
///
/// Contains the server base URL and authentication credentials
/// for accessing files on the server.
class FileServerConfig extends Equatable {
  /// Base URL of the file server (e.g., https://example.com/files).
  final String baseUrl;

  /// Username for Basic HTTP Authentication.
  final String username;

  /// Password for Basic HTTP Authentication.
  final String password;

  /// Whether the server requires authentication.
  bool get requiresAuth => username.isNotEmpty || password.isNotEmpty;

  const FileServerConfig({
    required this.baseUrl,
    this.username = '',
    this.password = '',
  });

  /// Creates a copy of this config with the given fields replaced.
  FileServerConfig copyWith({
    String? baseUrl,
    String? username,
    String? password,
  }) {
    return FileServerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  /// Returns true if this config is valid (has a non-empty baseUrl).
  bool get isValid => baseUrl.isNotEmpty;

  @override
  List<Object?> get props => [baseUrl, username, password];
}

