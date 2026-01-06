import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'channel_model.g.dart';

@HiveType(typeId: 0)
class ChannelModel extends Equatable {
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
  });

  @override
  List<Object?> get props => [id, name, logoUrl, url, group];
}
