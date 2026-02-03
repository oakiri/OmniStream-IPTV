import 'package:equatable/equatable.dart';

/// Basic XMLTV program.
class EpgProgram extends Equatable {
  final String title;
  final DateTime start;
  final DateTime stop;
  final String? description;

  const EpgProgram({
    required this.title,
    required this.start,
    required this.stop,
    this.description,
  });

  Duration get duration => stop.difference(start);

  /// Convenience alias used by some UI layers.
  /// Stored times are treated as UTC; convert for display with `.toLocal()`.
  DateTime get startUtc => start.toUtc();
  DateTime get stopUtc => stop.toUtc();

  @override
  List<Object?> get props => [title, start, stop, description];

  Map<String, dynamic> toJson() => {
        'title': title,
        'start': start.toIso8601String(),
        'stop': stop.toIso8601String(),
        'description': description,
      };

  static EpgProgram fromJson(Map<String, dynamic> json) => EpgProgram(
        title: (json['title'] ?? '').toString(),
        start: DateTime.parse(json['start'] as String),
        stop: DateTime.parse(json['stop'] as String),
        description: (json['description'] as String?),
      );
}

/// NOW/NEXT bundle for a channel.
class EpgNowNext extends Equatable {
  final String channelId; // XMLTV channel id
  final EpgProgram? now;
  final EpgProgram? next;

  const EpgNowNext({
    required this.channelId,
    this.now,
    this.next,
  });

  @override
  List<Object?> get props => [channelId, now, next];

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'now': now?.toJson(),
        'next': next?.toJson(),
      };

  static EpgNowNext fromJson(Map<String, dynamic> json) => EpgNowNext(
        channelId: (json['channelId'] ?? '').toString(),
        now: (json['now'] is Map) ? EpgProgram.fromJson(Map<String, dynamic>.from(json['now'] as Map)) : null,
        next: (json['next'] is Map) ? EpgProgram.fromJson(Map<String, dynamic>.from(json['next'] as Map)) : null,
      );
}

enum EpgMode { auto, override }

class EpgSettings extends Equatable {
  final EpgMode mode;
  final String? overrideUrl;
  final String fallbackCountry; // ISO 3166-1 alpha-2
  final int refreshHours;
  final bool preferGzip;

  const EpgSettings({
    required this.mode,
    required this.overrideUrl,
    required this.fallbackCountry,
    required this.refreshHours,
    required this.preferGzip,
  });

  @override
  List<Object?> get props => [mode, overrideUrl, fallbackCountry, refreshHours, preferGzip];

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'overrideUrl': overrideUrl,
        'fallbackCountry': fallbackCountry,
        'refreshHours': refreshHours,
        'preferGzip': preferGzip,
      };

  static EpgSettings fromJson(Map<String, dynamic> json) => EpgSettings(
        mode: ((json['mode'] ?? 'auto').toString() == 'override') ? EpgMode.override : EpgMode.auto,
        overrideUrl: (json['overrideUrl'] as String?),
        fallbackCountry: (json['fallbackCountry'] ?? 'ES').toString(),
        refreshHours: int.tryParse((json['refreshHours'] ?? 6).toString()) ?? 6,
        preferGzip: (json['preferGzip'] as bool?) ?? true,
      );

  EpgSettings copyWith({
    EpgMode? mode,
    String? overrideUrl,
    String? fallbackCountry,
    int? refreshHours,
    bool? preferGzip,
  }) {
    return EpgSettings(
      mode: mode ?? this.mode,
      overrideUrl: overrideUrl ?? this.overrideUrl,
      fallbackCountry: fallbackCountry ?? this.fallbackCountry,
      refreshHours: refreshHours ?? this.refreshHours,
      preferGzip: preferGzip ?? this.preferGzip,
    );
  }
}
