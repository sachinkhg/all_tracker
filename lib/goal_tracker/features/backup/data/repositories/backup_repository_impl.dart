import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/constants.dart';
import '../../core/encryption_service.dart';
import '../../core/device_info_service.dart';
import '../datasources/google_auth_datasource.dart';
import '../datasources/drive_api_client.dart';
import '../datasources/backup_metadata_local_datasource.dart';
import '../services/backup_builder_service.dart';
import '../models/backup_manifest.dart';
import '../models/backup_metadata_model.dart';
import '../../domain/entities/backup_metadata.dart';
import '../../domain/entities/backup_result.dart';
import '../../domain/entities/restore_result.dart';
import '../../domain/entities/backup_progress.dart';
import '../../domain/entities/backup_mode.dart';
import '../../domain/repositories/backup_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Implementation of BackupRepository.
class BackupRepositoryImpl implements BackupRepository {
  final GoogleAuthDataSource _googleAuth;
  final DriveApiClient _driveApi;
  final EncryptionService _encryptionService;
  final BackupBuilderService _backupBuilder;
  final BackupMetadataLocalDataSource _metadataDataSource;
  final DeviceInfoService _deviceInfoService;

  final StreamController<BackupProgress> _progressController =
      StreamController<BackupProgress>.broadcast();

  BackupRepositoryImpl({
    required GoogleAuthDataSource googleAuth,
    required DriveApiClient driveApi,
    required EncryptionService encryptionService,
    required BackupBuilderService backupBuilder,
    required BackupMetadataLocalDataSource metadataDataSource,
    required DeviceInfoService deviceInfoService,
  })  : _googleAuth = googleAuth,
        _driveApi = driveApi,
        _encryptionService = encryptionService,
        _backupBuilder = backupBuilder,
        _metadataDataSource = metadataDataSource,
        _deviceInfoService = deviceInfoService;

  @override
  Stream<BackupProgress> get backupProgress => _progressController.stream;

  @override
  Future<BackupResult> createBackup({
    required BackupMode mode,
    String? passphrase,
  }) async {
    try {
      _emitProgress('Exporting data', 0.1);

      // Build snapshot
      final snapshot = await _backupBuilder.createBackupSnapshot();
      _emitProgress('Compressing data', 0.3);

      // Compress
      final compressedData = await _backupBuilder.compressSnapshot(snapshot);

      // Encrypt
      _emitProgress('Encrypting backup', 0.5);
      Uint8List key;
      String? kdfSalt;
      int? kdfIterations;

      if (mode == BackupMode.e2ee && passphrase != null) {
        kdfSalt = base64Encode(await _encryptionService.generateSalt());
        kdfIterations = 200000;
        final saltBytes = base64Decode(kdfSalt);
        key = await _encryptionService.deriveKeyFromPassphrase(
          passphrase,
          saltBytes,
        );
      } else {
        key = await _encryptionService.generateDeviceKey();
      }

      final encryptionResult = await _encryptionService.encryptData(compressedData, key);

      // Build manifest
      final deviceId = await _deviceInfoService.getDeviceId();
      final manifest = await _backupBuilder.buildManifest(
        deviceId: deviceId,
        dataChunks: [Uint8List.fromList(utf8.encode(jsonEncode(encryptionResult)))],
        iv: base64Decode(encryptionResult['iv']!),
        kdfSalt: kdfSalt,
        kdfIterations: kdfIterations,
        isE2EE: mode == BackupMode.e2ee,
      );

      // Combine manifest + encrypted data
      final backupData = {
        'manifest': manifest.toJson(),
        'ciphertext': encryptionResult['ciphertext'],
        'mac': encryptionResult['mac'],
      };

      final backupBytes = Uint8List.fromList(utf8.encode(jsonEncode(backupData)));
      final fileName = 'goaltracker-backup-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${deviceId}.enc';

      _emitProgress('Uploading to Google Drive', 0.8);

      // Upload to Drive
      final appProperties = {
        'deviceId': deviceId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isE2EE': (mode == BackupMode.e2ee).toString(),
        'schemaVersion': '7',
      };

      final fileId = await _driveApi.uploadFile(fileName, backupBytes, appProperties);

      // Save metadata locally
      final deviceDescription = await _deviceInfoService.getDeviceDescription();
      final metadata = BackupMetadataModel(
        id: fileId,
        fileName: fileName,
        createdAt: DateTime.now(),
        deviceId: deviceId,
        sizeBytes: backupBytes.length,
        isE2EE: mode == BackupMode.e2ee,
        deviceDescription: deviceDescription,
      );

      await _metadataDataSource.create(metadata);

      _emitProgress('Completed', 1.0);

      return BackupSuccess(backupId: fileId, sizeBytes: backupBytes.length);
    } catch (e) {
      return BackupFailure(error: e.toString());
    }
  }

  @override
  Future<List<BackupMetadata>> listBackups() async {
    try {
      final driveFiles = await _driveApi.listBackups();
      final localMetadata = await _metadataDataSource.getAll();

      // Merge and convert to domain entities
      final backups = <BackupMetadata>[];
      for (final file in driveFiles) {
        final localMeta = localMetadata.firstWhere(
          (m) => m.id == file['id'],
          orElse: () => _createMetadataFromDriveFile(file),
        );

        backups.add(BackupMetadata(
          id: localMeta.id,
          fileName: localMeta.fileName,
          createdAt: localMeta.createdAt,
          deviceId: localMeta.deviceId,
          deviceDescription: localMeta.deviceDescription,
          sizeBytes: localMeta.sizeBytes,
          isE2EE: localMeta.isE2EE,
        ));
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }

  BackupMetadataModel _createMetadataFromDriveFile(Map<String, dynamic> file) {
    return BackupMetadataModel(
      id: file['id'] as String,
      fileName: file['name'] as String? ?? 'unknown',
      createdAt: _parseDriveDate(file['createdTime'] as String?),
      deviceId: file['appProperties']?['deviceId'] as String? ?? 'unknown',
      sizeBytes: int.tryParse(file['size'] as String? ?? '0') ?? 0,
      isE2EE: file['appProperties']?['isE2EE'] == 'true',
      deviceDescription: null,
    );
  }

  DateTime _parseDriveDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Future<RestoreResult> restoreBackup({
    required String backupId,
    String? passphrase,
  }) async {
    try {
      _emitProgress('Downloading backup', 0.2);

      // Download from Drive
      final backupBytes = await _driveApi.downloadFile(backupId);
      final backupJson = jsonDecode(utf8.decode(backupBytes)) as Map<String, dynamic>;

      _emitProgress('Decrypting backup', 0.4);

      // Get metadata to determine encryption mode
      final localMetadata = await _metadataDataSource.getAll();
      final metadata = localMetadata.firstWhere((m) => m.id == backupId);

      // Decrypt
      final key = metadata.isE2EE && passphrase != null
          ? await _derivePassphraseKey(backupJson, passphrase)
          : await _encryptionService.generateDeviceKey();

      final encryptionResult = {
        'iv': backupJson['manifest']['encryption']['iv'] as String,
        'ciphertext': backupJson['ciphertext'] as String,
        'mac': backupJson['mac'] as String,
      };

      final decryptedData = await _encryptionService.decryptData(encryptionResult, key);

      _emitProgress('Restoring data', 0.7);

      // Parse and import
      final snapshot = jsonDecode(utf8.decode(decryptedData)) as Map<String, dynamic>;

      // Clear existing boxes
      await _clearAllBoxes();

      // Import data (reusing logic from backup_restore.dart)
      await _importData(snapshot);

      _emitProgress('Completed', 1.0);

      return RestoreSuccess();
    } catch (e) {
      return RestoreFailure(error: e.toString());
    }
  }

  Future<Uint8List> _derivePassphraseKey(Map<String, dynamic> backupJson, String passphrase) async {
    final manifest = BackupManifest.fromJson(backupJson['manifest'] as Map<String, dynamic>);
    if (manifest.kdf == null) {
      throw Exception('Backup is E2EE but no KDF config found');
    }

    final salt = base64Decode(manifest.kdf!.salt);
    return await _encryptionService.deriveKeyFromPassphrase(passphrase, salt);
  }

  Future<void> _clearAllBoxes() async {
    await Hive.box<dynamic>(goalBoxName).clear();
    await Hive.box<dynamic>(milestoneBoxName).clear();
    await Hive.box<dynamic>(taskBoxName).clear();
    await Hive.box<dynamic>(habitBoxName).clear();
    await Hive.box<dynamic>(habitCompletionBoxName).clear();
  }

  Future<void> _importData(Map<String, dynamic> snapshot) async {
    // TODO: Implement full import logic
    // This would involve parsing all entity types from the snapshot
    // and importing them into Hive boxes using the existing mappers
    // from lib/goal_tracker/features/import_export_mappers.dart
    
    throw UnimplementedError('Data import functionality needs to be implemented');
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    try {
      await _driveApi.deleteFile(backupId);
      await _metadataDataSource.delete(backupId);
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  void _emitProgress(String stage, double progress) {
    _progressController.add(BackupProgress(stage: stage, progress: progress));
  }
}

