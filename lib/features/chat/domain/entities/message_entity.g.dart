// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageEntityAdapter extends TypeAdapter<MessageEntity> {
  @override
  final int typeId = 5;

  @override
  MessageEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageEntity(
      text: fields[0] as String,
      isMe: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MessageEntity obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.isMe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
