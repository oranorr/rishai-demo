// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welness_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WelnessEntityAdapter extends TypeAdapter<WelnessEntity> {
  @override
  final int typeId = 19;

  @override
  WelnessEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WelnessEntity(
      consumedMeals: (fields[0] as List).cast<DiaryMeal>(),
      welnessPercentage: fields[1] as double,
      consumedMacros: fields[2] as MacrosBreakdown,
    );
  }

  @override
  void write(BinaryWriter writer, WelnessEntity obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.consumedMeals)
      ..writeByte(1)
      ..write(obj.welnessPercentage)
      ..writeByte(2)
      ..write(obj.consumedMacros);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WelnessEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
