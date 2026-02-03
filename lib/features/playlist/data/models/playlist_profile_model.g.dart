// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistProfileModelAdapter extends TypeAdapter<PlaylistProfileModel> {
  @override
  final int typeId = 1;

  @override
  PlaylistProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistProfileModel(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      userId: fields[3] as String,
      type: fields[4] as String?,
      lastUsed: fields[5] as DateTime?,
      expirationDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistProfileModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.lastUsed)
      ..writeByte(6)
      ..write(obj.expirationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
