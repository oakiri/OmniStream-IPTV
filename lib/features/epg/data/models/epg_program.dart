import 'package:equatable/equatable.dart';

class EpgProgram extends Equatable {
  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? desc;

  const EpgProgram({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.desc,
  });

  @override
  List<Object?> get props => [channelId, start, stop, title, desc];
}
