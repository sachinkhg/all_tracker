// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_component_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentComponentModelAdapter
    extends TypeAdapter<InvestmentComponentModel> {
  @override
  final int typeId = 6;

  @override
  InvestmentComponentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentComponentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      percentage: fields[2] as double,
      minLimit: fields[3] as double?,
      maxLimit: fields[4] as double?,
      multipleOf: fields[5] as double?,
      priority: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentComponentModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.percentage)
      ..writeByte(3)
      ..write(obj.minLimit)
      ..writeByte(4)
      ..write(obj.maxLimit)
      ..writeByte(5)
      ..write(obj.multipleOf)
      ..writeByte(6)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentComponentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
