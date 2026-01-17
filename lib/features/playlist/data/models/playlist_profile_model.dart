import 'package:hive/hive.dart';
import '../../domain/entities/playlist_profile.dart';

@HiveType(typeId: 5)
class PlaylistProfileModel extends PlaylistProfile with HiveObjectMixin {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final String hiveName;

  @HiveField(2)
  final String hiveUrl;

  @HiveField(3)
  final String? hiveType;

  @HiveField(4)
  final DateTime? hiveLastUsed;

  PlaylistProfileModel({
    required this.hiveId,
    required this.hiveName,
    required this.hiveUrl,
    String? hiveType,
    DateTime? hiveLastUsed,
  })  : hiveType = hiveType,
        hiveLastUsed = hiveLastUsed,
        super(
          id: hiveId,
          name: hiveName,
          url: hiveUrl,
          type: hiveType,
          lastUsed: hiveLastUsed,
        );

  factory PlaylistProfileModel.fromEntity(PlaylistProfile p) {
    return PlaylistProfileModel(
      hiveId: p.id,
      hiveName: p.name,
      hiveUrl: p.url,
      hiveType: p.type,
      hiveLastUsed: p.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': hiveId,
        'name': hiveName,
        'url': hiveUrl,
        'type': hiveType,
        'lastUsed': hiveLastUsed?.toIso8601String(),
      };

  factory PlaylistProfileModel.fromJson(Map<String, dynamic> json) {
    final lastUsedRaw = json['lastUsed'];
    DateTime? lastUsed;
    if (lastUsedRaw is String && lastUsedRaw.isNotEmpty) {
      lastUsed = DateTime.tryParse(lastUsedRaw);
    }

    return PlaylistProfileModel(
      hiveId: (json['id'] ?? '').toString(),
      hiveName: (json['name'] ?? '').toString(),
      hiveUrl: (json['url'] ?? '').toString(),
      hiveType: json['type']?.toString(),
      hiveLastUsed: lastUsed,
    );
  }
}

class PlaylistProfileModelAdapter extends TypeAdapter<PlaylistProfileModel> {
  @override
  final int typeId = 5;

  @override
  PlaylistProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return PlaylistProfileModel(
      hiveId: fields[0] as String,
      hiveName: fields[1] as String,
      hiveUrl: fields[2] as String,
      hiveType: fields[3] as String?,
      hiveLastUsed: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistProfileModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.hiveId)
      ..writeByte(1)
      ..write(obj.hiveName)
      ..writeByte(2)
      ..write(obj.hiveUrl)
      ..writeByte(3)
      ..write(obj.hiveType)
      ..writeByte(4)
      ..write(obj.hiveLastUsed);
  }
}
