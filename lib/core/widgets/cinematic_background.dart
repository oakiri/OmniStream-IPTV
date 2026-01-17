import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/cinematic_theme.dart';

class CinematicBackground extends StatelessWidget {
  final Widget child;
  final bool showNoise;

  const CinematicBackground({
    super.key,
    required this.child,
    this.showNoise = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: CinematicTheme.backgroundGradient),
          ),
        ),
        if (showNoise)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NoisePainter(),
              ),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    final random = Random(42);
    final count = (size.width * size.height * 0.00012).toInt().clamp(120, 420);
    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawPoints(PointMode.points, [Offset(dx, dy)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
