// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_preferences_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodPreferencesAdapter extends TypeAdapter<FoodPreferences> {
  @override
  final int typeId = 2;

  @override
  FoodPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodPreferences(
      diets: (fields[0] as List).cast<String>(),
      cuisines: (fields[1] as List).cast<String>(),
      restrictions: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, FoodPreferences obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.diets)
      ..writeByte(1)
      ..write(obj.cuisines)
      ..writeByte(2)
      ..write(obj.restrictions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
