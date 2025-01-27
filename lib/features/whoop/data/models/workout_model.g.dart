// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutModelAdapter extends TypeAdapter<WorkoutModel> {
  @override
  final int typeId = 14;

  @override
  WorkoutModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutModel(
      id: fields[0] as int,
      userId: fields[1] as int,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      start: fields[4] as DateTime,
      timezoneOffset: fields[6] as String,
      sportId: fields[7] as int,
      scoreState: fields[8] as String,
      score: fields[9] as WorkoutScore?,
      end: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.start)
      ..writeByte(5)
      ..write(obj.end)
      ..writeByte(6)
      ..write(obj.timezoneOffset)
      ..writeByte(7)
      ..write(obj.sportId)
      ..writeByte(8)
      ..write(obj.scoreState)
      ..writeByte(9)
      ..write(obj.score);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutScoreAdapter extends TypeAdapter<WorkoutScore> {
  @override
  final int typeId = 15;

  @override
  WorkoutScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutScore(
      strain: fields[0] as double,
      averageHeartRate: fields[1] as int,
      maxHeartRate: fields[2] as int,
      kilojoule: fields[3] as double,
      percentRecorded: fields[4] as double,
      distanceMeter: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutScore obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.strain)
      ..writeByte(1)
      ..write(obj.averageHeartRate)
      ..writeByte(2)
      ..write(obj.maxHeartRate)
      ..writeByte(3)
      ..write(obj.kilojoule)
      ..writeByte(4)
      ..write(obj.percentRecorded)
      ..writeByte(5)
      ..write(obj.distanceMeter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
