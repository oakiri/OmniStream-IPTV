import 'package:hive/hive.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

part 'channel_model.g.dart';

@HiveType(typeId: 0)
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

  factory ChannelModel.fromEntity(Channel channel) {
    return ChannelModel(
      id: channel.id,
      name: channel.name,
      logoUrl: channel.logoUrl,
      url: channel.url,
      group: channel.group,
    );
  }
}