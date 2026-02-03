import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.94, end: 1.00)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    _c.forward();

    // Muy corto y elegante: total ~700ms.
    _t = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      context.go('/playlist');
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo premium: negro + glow sutil + marca "fantasma".
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF0B1220),
                  Color(0xFF000000),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // Marca grande muy tenue (no recorta, no "canta" en portrait).
          Center(
            child: Opacity(
              opacity: 0.10,
              child: Transform.scale(
                scale: 1.35,
                child: Image.asset(
                  'assets/branding/vivid_mark.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),

          // Lockup principal (responsive, sin cortes).
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final size = MediaQuery.of(context).size;
                  final logoW = math.min(size.width * 0.78, 420.0);
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.black.withOpacity(0.20),
                        ),
                        child: Image.asset(
                          'assets/branding/vivid_lockup.png',
                          width: logoW,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
