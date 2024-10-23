// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataEntityAdapter extends TypeAdapter<UserDataEntity> {
  @override
  final int typeId = 13;

  @override
  UserDataEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserDataEntity(
      workouts: (fields[0] as List).cast<WorkoutModel>(),
      userWeightLbs: fields[1] as double,
      gender: fields[2] as Gender,
      strainValue: fields[3] as double,
      recoveryScore: fields[4] as int,
      sleepPerformance: fields[5] as int,
      calorieGoal: fields[6] as int,
      askTime: fields[7] as DateTime,
      userId: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserDataEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.workouts)
      ..writeByte(1)
      ..write(obj.userWeightLbs)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.strainValue)
      ..writeByte(4)
      ..write(obj.recoveryScore)
      ..writeByte(5)
      ..write(obj.sleepPerformance)
      ..writeByte(6)
      ..write(obj.calorieGoal)
      ..writeByte(7)
      ..write(obj.askTime)
      ..writeByte(8)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
