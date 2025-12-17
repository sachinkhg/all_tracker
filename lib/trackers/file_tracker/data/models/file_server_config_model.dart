import 'package:hive/hive.dart';
import '../../domain/entities/file_server_config.dart';

part 'file_server_config_model.g.dart'; // Generated via build_runner

/// Hive model for storing file server configuration.
///
/// TypeId: 30 (as documented in migration_notes.md)
/// 
/// Migration note: serverName was added in a later version (field 3).
/// Field order maintained for backward compatibility:
/// - Field 0: baseUrl (existing)
/// - Field 1: username (existing)
/// - Field 2: password (existing)
/// - Field 3: serverName (new, nullable)
@HiveType(typeId: 30)
class FileServerConfigModel extends HiveObject {
  /// Base URL of the file server.
  @HiveField(0)
  String baseUrl;

  /// Username for Basic HTTP Authentication.
  @HiveField(1)
  String username;

  /// Password for Basic HTTP Authentication.
  @HiveField(2)
  String password;

  /// Unique name/identifier for this server configuration.
  /// Nullable to support migration from old data format.
  @HiveField(3)
  String? serverName;

  FileServerConfigModel({
    required this.baseUrl,
    this.username = '',
    this.password = '',
    this.serverName,
  }) {
    // Generate a default server name from URL if not provided (for migration)
    if (serverName == null || serverName!.isEmpty) {
      serverName = _generateServerNameFromUrl(baseUrl);
    }
  }

  /// Generates a server name from the URL for migration purposes.
  static String _generateServerNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isNotEmpty) {
        // Use hostname as server name, remove common prefixes
        return host.replaceAll('www.', '').split('.').first;
      }
    } catch (e) {
      // If URL parsing fails, use a generic name
    }
    return 'Server';
  }

  /// Factory constructor to build a [FileServerConfigModel] from a domain entity.
  factory FileServerConfigModel.fromEntity(FileServerConfig config) =>
      FileServerConfigModel(
        serverName: config.serverName,
        baseUrl: config.baseUrl,
        username: config.username,
        password: config.password,
      );

  /// Converts this model back into a domain [FileServerConfig] entity.
  FileServerConfig toEntity() {
    // Ensure serverName is never null (use generated name if needed)
    final name = serverName ?? _generateServerNameFromUrl(baseUrl);
    return FileServerConfig(
      serverName: name,
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }

  /// Creates a copy of this model with the given fields replaced.
  FileServerConfigModel copyWith({
    String? serverName,
    String? baseUrl,
    String? username,
    String? password,
  }) {
    final newServerName = serverName ?? this.serverName;
    final newBaseUrl = baseUrl ?? this.baseUrl;
    return FileServerConfigModel(
      serverName: newServerName,
      baseUrl: newBaseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

