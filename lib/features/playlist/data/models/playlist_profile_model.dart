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

  const PlaylistProfileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.userId,
  }) : super(id: id, name: name, url: url, userId: userId);

  factory PlaylistProfileModel.fromEntity(PlaylistProfile profile) {
    return PlaylistProfileModel(
      id: profile.id,
      name: profile.name,
      url: profile.url,
      userId: profile.userId ?? 'local',
    );
  }
}