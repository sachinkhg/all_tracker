// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_server_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileServerConfigModelAdapter extends TypeAdapter<FileServerConfigModel> {
  @override
  final int typeId = 30;

  @override
  FileServerConfigModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileServerConfigModel(
      baseUrl: fields[0] as String,
      username: fields[1] as String,
      password: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileServerConfigModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.baseUrl)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileServerConfigModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
