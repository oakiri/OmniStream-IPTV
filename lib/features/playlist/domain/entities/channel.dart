import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String url;
  // Esta es la propiedad que el compilador no encontraba
  final String? group;
  final String? userAgent; // A�adido por si acaso lo usas luego
  // A�adimos tambi�n estas por si acaso las usas en otro sitio (opcional)
  final String? groupTitle;
  final String? tvgId;
  final String? tvgName;

  const Channel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.url,
    this.group,
    this.userAgent,
    this.groupTitle,
    this.tvgId,
    this.tvgName,
  });

  @override
  List<Object?> get props =>
      [id, name, logoUrl, url, group, userAgent, groupTitle, tvgId, tvgName];
}
