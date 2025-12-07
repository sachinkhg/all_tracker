// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_file_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CloudFileModelAdapter extends TypeAdapter<CloudFileModel> {
  @override
  final int typeId = 31;

  @override
  CloudFileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CloudFileModel(
      url: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      size: fields[3] as int?,
      modifiedDateMs: fields[4] as int?,
      folder: fields[5] as String,
      mimeType: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CloudFileModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.modifiedDateMs)
      ..writeByte(5)
      ..write(obj.folder)
      ..writeByte(6)
      ..write(obj.mimeType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudFileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
