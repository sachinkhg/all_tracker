// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'component_allocation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComponentAllocationModelAdapter
    extends TypeAdapter<ComponentAllocationModel> {
  @override
  final int typeId = 12;

  @override
  ComponentAllocationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComponentAllocationModel(
      componentId: fields[0] as String,
      allocatedAmount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ComponentAllocationModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.componentId)
      ..writeByte(1)
      ..write(obj.allocatedAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentAllocationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
