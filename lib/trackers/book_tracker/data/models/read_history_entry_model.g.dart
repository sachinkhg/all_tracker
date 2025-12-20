// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_history_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadHistoryEntryModelAdapter extends TypeAdapter<ReadHistoryEntryModel> {
  @override
  final int typeId = 33;

  @override
  ReadHistoryEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadHistoryEntryModel(
      dateStarted: fields[0] as DateTime?,
      dateRead: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadHistoryEntryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dateStarted)
      ..writeByte(1)
      ..write(obj.dateRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadHistoryEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
