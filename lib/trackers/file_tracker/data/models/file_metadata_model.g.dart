// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileMetadataModelAdapter extends TypeAdapter<FileMetadataModel> {
  @override
  final int typeId = 31;

  @override
  FileMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Handle migration from old format (4 fields) to new format (6 fields)
    if (numOfFields == 4) {
      // Old format: stableIdentifier, tags, notes, lastUpdated
      return FileMetadataModel(
        stableIdentifier: fields[0] as String,
        tags: (fields[1] as List).cast<String>(),
        notes: fields[2] as String?,
        cast: const [], // Default to empty list for old data
        viewMode: null, // Default to null for old data
        lastUpdated: fields[3] as DateTime,
      );
    } else {
      // New format: stableIdentifier, tags, notes, cast, viewMode, lastUpdated
      return FileMetadataModel(
        stableIdentifier: fields[0] as String,
        tags: (fields[1] as List).cast<String>(),
        notes: fields[2] as String?,
        cast: (fields[3] as List).cast<String>(),
        viewMode: fields[4] as String?,
        lastUpdated: fields[5] as DateTime,
      );
    }
  }

  @override
  void write(BinaryWriter writer, FileMetadataModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.stableIdentifier)
      ..writeByte(1)
      ..write(obj.tags)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.cast)
      ..writeByte(4)
      ..write(obj.viewMode)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
