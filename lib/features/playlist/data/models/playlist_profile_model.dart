import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';

part 'playlist_profile_model.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class PlaylistProfileModel extends PlaylistProfile {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String name;

  @HiveField(2)
  @override
  final String url;

  @HiveField(3)
  @override
  final DateTime lastUpdated;

  @HiveField(4)
  @override
  final bool isFavorite;

  const PlaylistProfileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
    required this.isFavorite,
  }) : super(
          id: id,
          name: name,
          url: url,
          lastUpdated: lastUpdated,
          isFavorite: isFavorite,
        );

  factory PlaylistProfileModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistProfileModelToJson(this);
}
