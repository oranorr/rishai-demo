// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiaryMealAdapter extends TypeAdapter<DiaryMeal> {
  @override
  final int typeId = 20;

  @override
  DiaryMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiaryMeal(
      title: fields[0] as String,
      type: fields[1] as String,
      macros: fields[2] as MacrosBreakdown,
    );
  }

  @override
  void write(BinaryWriter writer, DiaryMeal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.macros);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
