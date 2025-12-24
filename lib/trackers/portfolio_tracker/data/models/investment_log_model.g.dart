// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentLogModelAdapter extends TypeAdapter<InvestmentLogModel> {
  @override
  final int typeId = 35;

  @override
  InvestmentLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentLogModel(
      id: fields[0] as String,
      investmentId: fields[1] as String,
      purchaseDate: fields[2] as DateTime,
      quantity: fields[3] as double?,
      averageCostPrice: fields[4] as double?,
      costToAcquire: fields[5] as double?,
      currencyConversionAmount: fields[6] as double?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.investmentId)
      ..writeByte(2)
      ..write(obj.purchaseDate)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.averageCostPrice)
      ..writeByte(5)
      ..write(obj.costToAcquire)
      ..writeByte(6)
      ..write(obj.currencyConversionAmount)
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
      other is InvestmentLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
