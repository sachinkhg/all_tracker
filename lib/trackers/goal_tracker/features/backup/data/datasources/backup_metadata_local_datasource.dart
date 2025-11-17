import 'package:hive_flutter/hive_flutter.dart';
import '../models/backup_metadata_model.dart';

/// Local data source for backup ledger storage in Hive.
abstract class BackupMetadataLocalDataSource {
  Future<List<BackupMetadataModel>> getAll();
  Future<void> create(BackupMetadataModel metadata);
  Future<void> delete(String id);
  Future<void> clear();
}

class BackupMetadataLocalDataSourceImpl implements BackupMetadataLocalDataSource {
  final Box<BackupMetadataModel> _box;

  BackupMetadataLocalDataSourceImpl(this._box);

  @override
  Future<List<BackupMetadataModel>> getAll() async {
    return _box.values.toList();
  }

  @override
  Future<void> create(BackupMetadataModel metadata) async {
    await _box.put(metadata.id, metadata);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

