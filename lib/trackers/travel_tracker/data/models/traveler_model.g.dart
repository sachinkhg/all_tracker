// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traveler_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelerModelAdapter extends TypeAdapter<TravelerModel> {
  @override
  final int typeId = 21;

  @override
  TravelerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelerModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      name: fields[2] as String,
      relationship: fields[3] as String?,
      email: fields[4] as String?,
      phone: fields[5] as String?,
      notes: fields[6] as String?,
      isMainTraveler: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TravelerModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.relationship)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isMainTraveler)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
