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
    // Handle existing data that may not have duration and period fields
    final createdAt = fields.containsKey(7) ? (fields[7] as DateTime?) : null;
    final createdAtValue = createdAt ?? DateTime.now();
    
    // Format period from createdAt if period is missing (format: "MMM yyyy")
    String formatPeriod(DateTime date) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.year}';
    }
    
    // Safely extract duration and period, providing defaults for old data
    final duration = fields.containsKey(2) 
        ? (fields[2] as String?) 
        : null;
    final period = fields.containsKey(3) 
        ? (fields[3] as String?) 
        : null;
    
    return InvestmentPlanModel(
      id: (fields[0] as String?) ?? '',
      name: (fields[1] as String?) ?? '',
      duration: duration ?? 'Monthly',
      period: period ?? formatPeriod(createdAtValue),
      status: fields.containsKey(9) ? (fields[9] as String?) : null,
      incomeEntries: fields.containsKey(4) 
          ? ((fields[4] as List?)?.cast<IncomeEntryModel>() ?? <IncomeEntryModel>[])
          : <IncomeEntryModel>[],
      expenseEntries: fields.containsKey(5)
          ? ((fields[5] as List?)?.cast<ExpenseEntryModel>() ?? <ExpenseEntryModel>[])
          : <ExpenseEntryModel>[],
      allocations: fields.containsKey(6)
          ? ((fields[6] as List?)?.cast<ComponentAllocationModel>() ?? <ComponentAllocationModel>[])
          : <ComponentAllocationModel>[],
      createdAt: createdAtValue,
      updatedAt: fields.containsKey(8) ? (fields[8] as DateTime?) ?? DateTime.now() : DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentPlanModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.period)
      ..writeByte(9)
      ..write(obj.status)
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
