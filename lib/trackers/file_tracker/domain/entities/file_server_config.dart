import 'package:equatable/equatable.dart';

/// Domain entity representing the configuration for a file server.
///
/// Contains the server name, base URL, and authentication credentials
/// for accessing files on the server. The server name allows multiple
/// servers to be configured and switched between.
class FileServerConfig extends Equatable {
  /// Unique name/identifier for this server configuration.
  /// Used to store and retrieve server configs independently of URL.
  final String serverName;

  /// Base URL of the file server (e.g., https://example.com/files).
  final String baseUrl;

  /// Username for Basic HTTP Authentication.
  final String username;

  /// Password for Basic HTTP Authentication.
  final String password;

  /// Whether the server requires authentication.
  bool get requiresAuth => username.isNotEmpty || password.isNotEmpty;

  const FileServerConfig({
    required this.serverName,
    required this.baseUrl,
    this.username = '',
    this.password = '',
  });

  /// Creates a copy of this config with the given fields replaced.
  FileServerConfig copyWith({
    String? serverName,
    String? baseUrl,
    String? username,
    String? password,
  }) {
    return FileServerConfig(
      serverName: serverName ?? this.serverName,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  /// Returns true if this config is valid (has a non-empty baseUrl and serverName).
  bool get isValid => baseUrl.isNotEmpty && serverName.isNotEmpty;

  @override
  List<Object?> get props => [serverName, baseUrl, username, password];
}

