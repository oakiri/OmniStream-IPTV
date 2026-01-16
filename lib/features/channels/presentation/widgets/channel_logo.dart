import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart'; // Ya ten�as shimmer en tu pubspec, �us�moslo!

class ChannelLogo extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;

  const ChannelLogo({
    Key? key,
    required this.url,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. URL inv�lida o vac�a
    if (url == null || url!.isEmpty) {
      return _buildErrorPlaceholder();
    }

    final validUrl = url!;

    // 2. Detectar si es un SVG (Vectorial)
    // Muchas listas IPTV usan .svg y esto es lo que rompe Image.network
    if (validUrl.toLowerCase().endsWith('.svg')) {
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.network(
          validUrl,
          fit: fit,
          placeholderBuilder: (BuildContext context) => _buildShimmerLoader(),
        ),
      );
    }

    // 3. Im�genes normales (JPG, PNG, WEBP)
    // Usamos CachedNetworkImage para mejor rendimiento en listas largas
    return CachedNetworkImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildShimmerLoader(),
      errorWidget: (context, url, error) {
        // Esto captura el error "Failed to decode" y muestra un icono
        // en lugar de romper la app o mostrar el c�rculo infinito.
        return _buildErrorPlaceholder();
      },
    );
  }

  // Widget de carga (Efecto brillo)
  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.black,
      ),
    );
  }

  // Widget de error (Icono TV)
  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.tv, color: Colors.white24, size: width * 0.5),
    );
  }
}
