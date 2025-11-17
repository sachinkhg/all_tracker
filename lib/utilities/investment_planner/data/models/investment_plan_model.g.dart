// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentPlanModelAdapter extends TypeAdapter<InvestmentPlanModel> {
  @override
  final int typeId = 9;

  @override
  InvestmentPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentPlanModel(
      id: fields[0] as String,
      name: fields[1] as String,
      duration: fields[2] as String,
      period: fields[3] as String,
      incomeEntries: (fields[4] as List).cast<IncomeEntryModel>(),
      expenseEntries: (fields[5] as List).cast<ExpenseEntryModel>(),
      allocations: (fields[6] as List).cast<ComponentAllocationModel>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentPlanModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.period)
      ..writeByte(4)
      ..write(obj.incomeEntries)
      ..writeByte(5)
      ..write(obj.expenseEntries)
      ..writeByte(6)
      ..write(obj.allocations)
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
      other is InvestmentPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
