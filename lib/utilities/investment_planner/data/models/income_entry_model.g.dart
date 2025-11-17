// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeEntryModelAdapter extends TypeAdapter<IncomeEntryModel> {
  @override
  final int typeId = 10;

  @override
  IncomeEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeEntryModel(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      amount: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeEntryModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
