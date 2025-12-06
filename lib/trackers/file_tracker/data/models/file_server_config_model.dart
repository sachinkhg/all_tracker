import 'package:hive/hive.dart';
import '../../domain/entities/file_server_config.dart';

part 'file_server_config_model.g.dart'; // Generated via build_runner

/// Hive model for storing file server configuration.
///
/// TypeId: 30 (as documented in migration_notes.md)
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

  FileServerConfigModel({
    required this.baseUrl,
    this.username = '',
    this.password = '',
  });

  /// Factory constructor to build a [FileServerConfigModel] from a domain entity.
  factory FileServerConfigModel.fromEntity(FileServerConfig config) =>
      FileServerConfigModel(
        baseUrl: config.baseUrl,
        username: config.username,
        password: config.password,
      );

  /// Converts this model back into a domain [FileServerConfig] entity.
  FileServerConfig toEntity() {
    return FileServerConfig(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }

  /// Creates a copy of this model with the given fields replaced.
  FileServerConfigModel copyWith({
    String? baseUrl,
    String? username,
    String? password,
  }) {
    return FileServerConfigModel(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

