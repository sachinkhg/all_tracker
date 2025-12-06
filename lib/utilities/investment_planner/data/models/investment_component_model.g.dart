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
    final fields = <int, dynamic>{};
    
    // Read all fields into map
    for (int i = 0; i < numOfFields; i++) {
      final fieldIndex = reader.readByte();
      final fieldValue = reader.read();
      fields[fieldIndex] = fieldValue;
    }
    
    // Migration: Handle old data format that didn't have multipleOf (field 5)
    // Old format: id(0), name(1), percentage(2), minLimit(3), maxLimit(4), priority(6)
    // New format: id(0), name(1), percentage(2), minLimit(3), maxLimit(4), multipleOf(5), priority(6)
    // Field 5 (multipleOf) is nullable, so old data without it will work fine
    
    return InvestmentComponentModel(
      id: (fields[0] as String?) ?? '',
      name: (fields[1] as String?) ?? '',
      percentage: (fields[2] as double?) ?? 0.0,
      minLimit: fields[3] as double?,
      maxLimit: fields[4] as double?,
      multipleOf: fields[5] as double?, // Nullable, so old data without this field is fine
      priority: (fields[6] as int?) ?? 0,
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
