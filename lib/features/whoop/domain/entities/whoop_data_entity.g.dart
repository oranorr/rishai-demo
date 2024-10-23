// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whoop_data_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WhoopDataEntityAdapter extends TypeAdapter<WhoopDataEntity> {
  @override
  final int typeId = 12;

  @override
  WhoopDataEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WhoopDataEntity(
      weekTdeeAverage: fields[0] as double,
      macros: fields[1] as MacrosBreakdown,
      askTime: fields[2] as DateTime,
      lastTdee: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WhoopDataEntity obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.weekTdeeAverage)
      ..writeByte(1)
      ..write(obj.macros)
      ..writeByte(2)
      ..write(obj.askTime)
      ..writeByte(3)
      ..write(obj.lastTdee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhoopDataEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
