// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_master_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentMasterModelAdapter extends TypeAdapter<InvestmentMasterModel> {
  @override
  final int typeId = 34;

  @override
  InvestmentMasterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentMasterModel(
      id: fields[0] as String,
      shortName: fields[1] as String,
      name: fields[2] as String,
      investmentCategory: fields[3] as String,
      investmentTrackingType: fields[4] as String,
      investmentCurrency: fields[5] as String,
      riskFactor: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentMasterModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shortName)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.investmentCategory)
      ..writeByte(4)
      ..write(obj.investmentTrackingType)
      ..writeByte(5)
      ..write(obj.investmentCurrency)
      ..writeByte(6)
      ..write(obj.riskFactor)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentMasterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
