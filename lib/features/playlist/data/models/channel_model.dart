import 'package:hive/hive.dart';

import '../../domain/entities/channel.dart';

@HiveType(typeId: 11)
class ChannelModel extends Channel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? logoUrl;

  @HiveField(3)
  final String url;

  @HiveField(4)
  final String? group;

  const ChannelModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.url,
    this.group,
  }) : super(
          id: id,
          name: name,
          logoUrl: logoUrl,
          url: url,
          group: group,
        );

  // Convertir de Entidad (Domain) a Modelo (Data)
  factory ChannelModel.fromEntity(Channel channel) {
    return ChannelModel(
      id: channel.id,
      name: channel.name,
      logoUrl: channel.logoUrl,
      url: channel.url,
      group: channel.group,
    );
  }

  // --- MÉTODOS AÑADIDOS PARA FIREBASE ---

  // Convertir de JSON (Firebase) a Modelo
  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin Nombre',
      logoUrl: json['logoUrl'] as String?,
      url: json['url'] as String? ?? '',
      group: json['group'] as String?,
    );
  }

  // Convertir de Modelo a JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'url': url,
      'group': group,
    };
  }
}

/// Adapter manual para evitar depender de archivos generados (*.g.dart).
class ChannelModelAdapter extends TypeAdapter<ChannelModel> {
  @override
  final int typeId = 11;

  @override
  ChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelModel(
      id: fields[0] as String,
      name: fields[1] as String,
      logoUrl: fields[2] as String?,
      url: fields[3] as String,
      group: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.logoUrl)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.group);
  }
}
