// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayEntityAdapter extends TypeAdapter<DayEntity> {
  @override
  final int typeId = 12;

  @override
  DayEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayEntity(
      directusId: fields[0] as int,
      weekTdeeAverage: fields[1] as int,
      macros: fields[2] as MacrosBreakdown,
      healthMetrics: fields[3] as HealthMetricsEntity,
      snap: fields[6] as ChatSnapshotEntity,
      dateTime: fields[5] as DateTime,
      cycleId: fields[7] as int?,
      mealPlanEntity: fields[4] as MealPlanEntity?,
      welnessEntity: fields[8] as WelnessEntity?,
    );
  }

  @override
  void write(BinaryWriter writer, DayEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.directusId)
      ..writeByte(1)
      ..write(obj.weekTdeeAverage)
      ..writeByte(2)
      ..write(obj.macros)
      ..writeByte(3)
      ..write(obj.healthMetrics)
      ..writeByte(4)
      ..write(obj.mealPlanEntity)
      ..writeByte(5)
      ..write(obj.dateTime)
      ..writeByte(6)
      ..write(obj.snap)
      ..writeByte(7)
      ..write(obj.cycleId)
      ..writeByte(8)
      ..write(obj.welnessEntity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
