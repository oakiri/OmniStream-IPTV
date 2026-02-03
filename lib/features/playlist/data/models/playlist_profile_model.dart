import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';

part 'playlist_profile_model.g.dart';

@HiveType(typeId: 1)
class PlaylistProfileModel extends PlaylistProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String? type;

  @HiveField(5)
  final DateTime? lastUsed;

  // NUEVO CAMPO (Índice 6)
  @HiveField(6)
  final DateTime? expirationDate;

  const PlaylistProfileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.userId,
    this.type,
    this.lastUsed,
    this.expirationDate,
  }) : super(
          id: id, 
          name: name, 
          url: url, 
          userId: userId,
          type: type,
          lastUsed: lastUsed,
          expirationDate: expirationDate,
        );

  factory PlaylistProfileModel.fromEntity(PlaylistProfile profile) {
    return PlaylistProfileModel(
      id: profile.id,
      name: profile.name,
      url: profile.url,
      userId: profile.userId ?? 'local',
      type: profile.type,
      lastUsed: profile.lastUsed,
      expirationDate: profile.expirationDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'userId': userId,
      'type': type,
      'lastUsed': lastUsed?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }
}