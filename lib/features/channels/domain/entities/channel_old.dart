import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  final String id;
  final String name;
  final String url;
  final String logoUrl;
  final String? groupTitle;
  final String? tvgId;
  final String? tvgName;

  const Channel({
    required this.id,
    required this.name,
    required this.url,
    required this.logoUrl,
    this.groupTitle,
    this.tvgId,
    this.tvgName,
  });

  @override
  List<Object?> get props =>
      [id, name, url, logoUrl, groupTitle, tvgId, tvgName];
}
