// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retirement_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RetirementPlanModelAdapter extends TypeAdapter<RetirementPlanModel> {
  @override
  final int typeId = 13;

  @override
  RetirementPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RetirementPlanModel(
      id: fields[0] as String,
      name: fields[1] as String,
      dob: fields[2] as DateTime,
      retirementAge: fields[3] as int,
      lifeExpectancy: fields[4] as int,
      inflationRate: fields[5] as double,
      postRetirementReturnRate: fields[6] as double,
      preRetirementReturnRate: fields[7] as double,
      preRetirementReturnRatioVariation: fields[8] as double,
      monthlyExpensesVariation: fields[9] as double,
      currentMonthlyExpenses: fields[10] as double,
      currentSavings: fields[11] as double,
      periodForIncome: fields[12] as double?,
      preRetirementReturnRateCalculated: fields[13] as double?,
      monthlyExpensesAtRetirement: fields[14] as double?,
      totalCorpusNeeded: fields[15] as double?,
      futureValueOfCurrentInvestment: fields[16] as double?,
      corpusRequiredToBuild: fields[17] as double?,
      monthlyInvestment: fields[18] as double?,
      yearlyInvestment: fields[19] as double?,
      createdAt: fields[20] as DateTime,
      updatedAt: fields[21] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RetirementPlanModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dob)
      ..writeByte(3)
      ..write(obj.retirementAge)
      ..writeByte(4)
      ..write(obj.lifeExpectancy)
      ..writeByte(5)
      ..write(obj.inflationRate)
      ..writeByte(6)
      ..write(obj.postRetirementReturnRate)
      ..writeByte(7)
      ..write(obj.preRetirementReturnRate)
      ..writeByte(8)
      ..write(obj.preRetirementReturnRatioVariation)
      ..writeByte(9)
      ..write(obj.monthlyExpensesVariation)
      ..writeByte(10)
      ..write(obj.currentMonthlyExpenses)
      ..writeByte(11)
      ..write(obj.currentSavings)
      ..writeByte(12)
      ..write(obj.periodForIncome)
      ..writeByte(13)
      ..write(obj.preRetirementReturnRateCalculated)
      ..writeByte(14)
      ..write(obj.monthlyExpensesAtRetirement)
      ..writeByte(15)
      ..write(obj.totalCorpusNeeded)
      ..writeByte(16)
      ..write(obj.futureValueOfCurrentInvestment)
      ..writeByte(17)
      ..write(obj.corpusRequiredToBuild)
      ..writeByte(18)
      ..write(obj.monthlyInvestment)
      ..writeByte(19)
      ..write(obj.yearlyInvestment)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetirementPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
