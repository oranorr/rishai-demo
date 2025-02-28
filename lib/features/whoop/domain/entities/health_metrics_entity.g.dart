// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_metrics_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthMetricsEntityAdapter extends TypeAdapter<HealthMetricsEntity> {
  @override
  final int typeId = 16;

  @override
  HealthMetricsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthMetricsEntity(
      bmi: fields[0] as int,
      lastTdee: fields[1] as int,
      bmr: fields[2] as int,
      bodyFatPerc: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HealthMetricsEntity obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bmi)
      ..writeByte(1)
      ..write(obj.lastTdee)
      ..writeByte(2)
      ..write(obj.bmr)
      ..writeByte(3)
      ..write(obj.bodyFatPerc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthMetricsEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
