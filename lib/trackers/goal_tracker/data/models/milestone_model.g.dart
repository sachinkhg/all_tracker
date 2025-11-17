// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MilestoneModelAdapter extends TypeAdapter<MilestoneModel> {
  @override
  final int typeId = 1;

  @override
  MilestoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilestoneModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      plannedValue: fields[3] as double?,
      actualValue: fields[4] as double?,
      targetDate: fields[5] as DateTime?,
      goalId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MilestoneModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.plannedValue)
      ..writeByte(4)
      ..write(obj.actualValue)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.goalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
