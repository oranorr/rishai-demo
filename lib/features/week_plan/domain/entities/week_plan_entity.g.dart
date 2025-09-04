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
      userId: fields[0] as String,
      plans: (fields[1] as List).cast<MealPlanEntity>(),
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      fitnessGoal: fields[4] as String,
      dietaryPreferences: fields[5] as String,
      cuisines: (fields[6] as List).cast<String>(),
      mealsTypes: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WeekPlanEntity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.plans)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.fitnessGoal)
      ..writeByte(5)
      ..write(obj.dietaryPreferences)
      ..writeByte(6)
      ..write(obj.cuisines)
      ..writeByte(7)
      ..write(obj.mealsTypes);
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
