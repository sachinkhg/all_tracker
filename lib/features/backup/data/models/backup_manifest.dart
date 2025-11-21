/// Manifest containing metadata about a backup.
/// 
/// This class represents the structure of the backup manifest JSON file.
class BackupManifest {
  final String version; // e.g., "1"
  final DateTime createdAt;
  final String appVersion; // e.g., "3.4.2"
  final int dbSchemaVersion; // Current schema version
  final String deviceId;
  final List<BackupFile> files;
  final KdfConfig? kdf; // null for device-key mode
  final EncryptionConfig encryption;

  BackupManifest({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.deviceId,
    required this.files,
    this.kdf,
    required this.encryption,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'dbSchemaVersion': dbSchemaVersion,
        'deviceId': deviceId,
        'files': files.map((f) => f.toJson()).toList(),
        if (kdf != null) 'kdf': kdf!.toJson(),
        'encryption': encryption.toJson(),
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        version: json['version'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        appVersion: json['appVersion'] as String,
        dbSchemaVersion: json['dbSchemaVersion'] as int,
        deviceId: json['deviceId'] as String,
        files: (json['files'] as List)
            .map((f) => BackupFile.fromJson(f as Map<String, dynamic>))
            .toList(),
        kdf: json['kdf'] != null
            ? KdfConfig.fromJson(json['kdf'] as Map<String, dynamic>)
            : null,
        encryption: EncryptionConfig.fromJson(
          json['encryption'] as Map<String, dynamic>,
        ),
      );
}

/// Represents a file included in the backup.
class BackupFile {
  final String path;
  final String sha256;

  BackupFile({required this.path, required this.sha256});

  Map<String, dynamic> toJson() => {
        'path': path,
        'sha256': sha256,
      };

  factory BackupFile.fromJson(Map<String, dynamic> json) => BackupFile(
        path: json['path'] as String,
        sha256: json['sha256'] as String,
      );
}

/// KDF (Key Derivation Function) configuration for E2EE backups.
class KdfConfig {
  final String alg; // "PBKDF2"
  final String salt; // base64 encoded
  final int iterations; // 200000

  KdfConfig({
    required this.alg,
    required this.salt,
    required this.iterations,
  });

  Map<String, dynamic> toJson() => {
        'alg': alg,
        'salt': salt,
        'iter': iterations,
      };

  factory KdfConfig.fromJson(Map<String, dynamic> json) => KdfConfig(
        alg: json['alg'] as String,
        salt: json['salt'] as String,
        iterations: json['iter'] as int,
      );
}

/// Encryption configuration.
class EncryptionConfig {
  final String alg; // "AES-256-GCM"
  final String iv; // base64 encoded

  EncryptionConfig({required this.alg, required this.iv});

  Map<String, dynamic> toJson() => {
        'alg': alg,
        'iv': iv,
      };

  factory EncryptionConfig.fromJson(Map<String, dynamic> json) =>
      EncryptionConfig(
        alg: json['alg'] as String,
        iv: json['iv'] as String,
      );
}

