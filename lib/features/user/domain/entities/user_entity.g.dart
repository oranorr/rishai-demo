// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserEntityAdapter extends TypeAdapter<UserEntity> {
  @override
  final int typeId = 0;

  @override
  UserEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserEntity(
      directusId: fields[0] as String,
      whoopId: fields[1] as int,
      email: fields[2] as String,
      name: fields[3] as String,
      daysIds: (fields[9] as List).cast<int>(),
      adaptyId: fields[10] as String?,
      age: fields[4] as int?,
      gender: fields[5] as Gender?,
      foodPreferences: fields[6] as FoodPreferences?,
      bodyMeasurements: fields[7] as BodyMeasurementsEntity?,
      userGoal: fields[8] as UserGoal?,
    );
  }

  @override
  void write(BinaryWriter writer, UserEntity obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.directusId)
      ..writeByte(1)
      ..write(obj.whoopId)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.age)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.foodPreferences)
      ..writeByte(7)
      ..write(obj.bodyMeasurements)
      ..writeByte(8)
      ..write(obj.userGoal)
      ..writeByte(9)
      ..write(obj.daysIds)
      ..writeByte(10)
      ..write(obj.adaptyId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = 1;

  @override
  Gender read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Gender.male;
      case 1:
        return Gender.female;
      default:
        return Gender.male;
    }
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    switch (obj) {
      case Gender.male:
        writer.writeByte(0);
        break;
      case Gender.female:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BodyMeasurementsEntityAdapter
    extends TypeAdapter<BodyMeasurementsEntity> {
  @override
  final int typeId = 3;

  @override
  BodyMeasurementsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMeasurementsEntity(
      height: fields[0] as double,
      weight: fields[1] as int,
      maxHeartRate: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurementsEntity obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.height)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.maxHeartRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurementsEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
