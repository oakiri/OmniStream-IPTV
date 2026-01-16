import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';

class EpgGuideView extends StatefulWidget {
  final List<Channel> channels;
  final Channel currentChannel;
  final Function(Channel) onChannelSelected;

  const EpgGuideView({
    Key? key,
    required this.channels,
    required this.currentChannel,
    required this.onChannelSelected,
  }) : super(key: key);

  @override
  State<EpgGuideView> createState() => _EpgGuideViewState();
}

class _EpgGuideViewState extends State<EpgGuideView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  late List<Channel> _filteredChannels;

  @override
  void initState() {
    super.initState();
    _filteredChannels = widget.channels;

    // Auto-scroll al canal actual tras renderizar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentChannel();
    });
  }

  void _scrollToCurrentChannel() {
    final index =
        _filteredChannels.indexWhere((c) => c.id == widget.currentChannel.id);
    if (index != -1 && _verticalController.hasClients) {
      // 60 es la altura aproximada de cada fila
      _verticalController.jumpTo((index * 80.0) - 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101010)
          .withOpacity(0.95), // Fondo oscuro semi-transparente
      child: SafeArea(
        child: Column(
          children: [
            // --- CABECERA DE LA GUÍA ---
            _buildHeader(),

            // --- CUERPO DE LA GUÍA (Parrilla) ---
            Expanded(
              child: Row(
                children: [
                  // COLUMNA IZQUIERDA: LISTA DE CANALES
                  SizedBox(
                    width: 250,
                    child: ListView.builder(
                      controller: _verticalController,
                      itemCount: _filteredChannels.length,
                      itemBuilder: (context, index) {
                        final channel = _filteredChannels[index];
                        final isSelected =
                            channel.id == widget.currentChannel.id;
                        return _buildChannelCell(channel, isSelected);
                      },
                    ),
                  ),

                  // COLUMNA DERECHA: LÍNEA DE TIEMPO (PROGRAMAS)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalController,
                      child: SizedBox(
                        width: 1000, // Ancho virtual de la línea de tiempo
                        child: ListView.builder(
                          controller:
                              _verticalController, // Scroll sincronizado verticalmente
                          physics:
                              const NeverScrollableScrollPhysics(), // Solo se mueve con la lista de canales
                          itemCount: _filteredChannels.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineRow();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.dvr, color: Colors.blueAccent),
              const SizedBox(width: 10),
              const Text("Guía de TV",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(DateFormat('EEE, d MMM').format(now),
                    style: const TextStyle(color: Colors.white70)),
              )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildChannelCell(Channel channel, bool isSelected) {
    return InkWell(
      onTap: () {
        widget.onChannelSelected(channel);
        Navigator.pop(context); // Cerrar guía al seleccionar
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          border: const Border(
              bottom: BorderSide(color: Colors.white12),
              right: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: channel.logoUrl != null
                  ? Image.network(channel.logoUrl!,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.tv, color: Colors.white54))
                  : const Icon(Icons.tv, color: Colors.white54),
            ),
            // Nombre
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.play_circle_fill,
                  color: Colors.blueAccent, size: 20),
          ],
        ),
      ),
    );
  }

  // Simulación visual de programas (ya que no tenemos XMLTV parser aún)
  Widget _buildTimelineRow() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Programa Actual (Simulado)
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Programación en Vivo",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Sin información EPG detallada",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
          // Programa Siguiente (Simulado)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                  child: Text("Siguiente programa...",
                      style: TextStyle(color: Colors.white38))),
            ),
          ),
        ],
      ),
    );
  }
}
