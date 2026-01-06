import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'epg_program_model.g.dart';

@HiveType(typeId: 2)
class EPGProgramModel extends Equatable {
  @HiveField(0)
  final String channelId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime start;

  @HiveField(4)
  final DateTime end;

  const EPGProgramModel({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [channelId, title, description, start, end];
}
