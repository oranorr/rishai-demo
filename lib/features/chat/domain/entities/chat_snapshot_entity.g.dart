// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_snapshot_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatSnapshotEntityAdapter extends TypeAdapter<ChatSnapshotEntity> {
  @override
  final int typeId = 4;

  @override
  ChatSnapshotEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSnapshotEntity(
      messages: (fields[0] as List).cast<MessageEntity>(),
      date: fields[1] as DateTime,
      requestsLeft: fields[2] as int,
      mealPlan: fields[3] as MealPlanEntity?,
      threadId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSnapshotEntity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.messages)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.requestsLeft)
      ..writeByte(3)
      ..write(obj.mealPlan)
      ..writeByte(4)
      ..write(obj.threadId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSnapshotEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
