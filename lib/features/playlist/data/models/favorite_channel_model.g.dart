// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_channel_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteChannelModelAdapter extends TypeAdapter<FavoriteChannelModel> {
  @override
  final int typeId = 4;

  @override
  FavoriteChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteChannelModel(
      id: fields[0] as String,
      name: fields[1] as String,
      logoUrl: fields[2] as String?,
      url: fields[3] as String,
      group: fields[4] as String?,
      userId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteChannelModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.logoUrl)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.group)
      ..writeByte(5)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteChannelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteChannelModel _$FavoriteChannelModelFromJson(
        Map<String, dynamic> json) =>
    FavoriteChannelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      url: json['url'] as String,
      group: json['group'] as String?,
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$FavoriteChannelModelToJson(
        FavoriteChannelModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoUrl': instance.logoUrl,
      'url': instance.url,
      'group': instance.group,
      'userId': instance.userId,
    };
