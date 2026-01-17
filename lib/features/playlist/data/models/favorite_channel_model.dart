import 'package:hive/hive.dart';

import '../../domain/entities/channel.dart';

@HiveType(typeId: 13)
class FavoriteChannelModel extends Channel {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String name;

  @HiveField(2)
  @override
  final String? logoUrl;

  @HiveField(3)
  @override
  final String url;

  @HiveField(4)
  @override
  final String? group;

  @HiveField(5)
  final String userId;

  const FavoriteChannelModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.url,
    this.group,
    required this.userId,
  }) : super(
          id: id,
          name: name,
          logoUrl: logoUrl,
          url: url,
          group: group,
        );

  factory FavoriteChannelModel.fromJson(Map<String, dynamic> json) {
    return FavoriteChannelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      url: json['url'] as String,
      group: json['group'] as String?,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'url': url,
      'group': group,
      'userId': userId,
    };
  }
}

/// Adapter manual para Hive.
class FavoriteChannelModelAdapter extends TypeAdapter<FavoriteChannelModel> {
  @override
  final int typeId = 13;

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
}
