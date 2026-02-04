// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epg_program_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EPGProgramModelAdapter extends TypeAdapter<EPGProgramModel> {
  @override
  final int typeId = 2;

  @override
  EPGProgramModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EPGProgramModel(
      channelId: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      start: fields[3] as DateTime,
      end: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EPGProgramModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.start)
      ..writeByte(4)
      ..write(obj.end);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EPGProgramModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
