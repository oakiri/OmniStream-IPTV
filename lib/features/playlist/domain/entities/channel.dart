import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String url;
  final String? group;

  const Channel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.url,
    this.group,
  });

  @override
  List<Object?> get props => [id, name, logoUrl, url, group];
}
