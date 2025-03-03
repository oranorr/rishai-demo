// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_plan_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeekPlanEntityAdapter extends TypeAdapter<WeekPlanEntity> {
  @override
  final int typeId = 17;

  @override
  WeekPlanEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeekPlanEntity(
      plans: (fields[0] as List).cast<MealPlanEntity>(),
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeekPlanEntity obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.plans)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekPlanEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
