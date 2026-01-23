import 'package:flutter/material.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import '../widgets/speed_test_widget.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SafeArea asegura que no pintemos debajo de la cámara (notch) o gestos
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Asegura que ocupe al menos toda la pantalla para centrar
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TEST DE VELOCIDAD",
                          style: CinematicStyles.title.copyWith(fontSize: 22, letterSpacing: 2),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Verifica tu conexión para streaming 4K",
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Contenedor con tamaño máximo controlado para evitar overflow en móviles pequeños
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 350, 
                            maxHeight: 350
                          ),
                          child: const AspectRatio(
                            aspectRatio: 1, 
                            child: SpeedTestWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}