// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_goal_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserGoalAdapter extends TypeAdapter<UserGoal> {
  @override
  final int typeId = 10;

  @override
  UserGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserGoal(
      goal: fields[0] as GoalType,
      modificator: fields[1] as double,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserGoal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.goal)
      ..writeByte(1)
      ..write(obj.modificator)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 11;

  @override
  GoalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalType.aesthetics;
      case 1:
        return GoalType.performance;
      case 2:
        return GoalType.recomp;
      case 3:
        return GoalType.optimize;
      default:
        return GoalType.aesthetics;
    }
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    switch (obj) {
      case GoalType.aesthetics:
        writer.writeByte(0);
        break;
      case GoalType.performance:
        writer.writeByte(1);
        break;
      case GoalType.recomp:
        writer.writeByte(2);
        break;
      case GoalType.optimize:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
