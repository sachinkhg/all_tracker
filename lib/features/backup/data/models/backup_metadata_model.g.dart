// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupMetadataModelAdapter extends TypeAdapter<BackupMetadataModel> {
  @override
  final int typeId = 5;

  @override
  BackupMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupMetadataModel(
      id: fields[0] as String,
      fileName: fields[1] as String,
      createdAt: fields[2] as DateTime,
      deviceId: fields[3] as String,
      sizeBytes: fields[4] as int,
      isE2EE: fields[5] as bool,
      deviceDescription: fields[6] as String?,
      name: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupMetadataModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.deviceId)
      ..writeByte(4)
      ..write(obj.sizeBytes)
      ..writeByte(5)
      ..write(obj.isE2EE)
      ..writeByte(6)
      ..write(obj.deviceDescription)
      ..writeByte(7)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
