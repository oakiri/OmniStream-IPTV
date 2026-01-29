import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

part 'favorite_channel_model.g.dart';

// NOTE: typeId MUST be unique across the whole app.
// EPGProgramModel already uses typeId: 2, so we move favorites to an unused id.
@HiveType(typeId: 4)
@JsonSerializable()
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

  factory FavoriteChannelModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteChannelModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteChannelModelToJson(this);
}
