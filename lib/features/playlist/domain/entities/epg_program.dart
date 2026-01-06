import 'package:equatable/equatable.dart';

class EPGProgram extends Equatable {
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  const EPGProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [channelId, title, description, start, end];
}
