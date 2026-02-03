import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';

import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/epg/epg_service.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';
import 'package:omnistream_iptv/injection_container.dart';

/// MÓDULO 3 — Guía Global tipo TVMate (Timeline 14h)
///
/// Ventana: NOW - 2h → NOW + 12h (14h)
/// - Filtro por categorías
/// - Búsqueda
/// - Lista de canales (izquierda) + timeline (derecha)
/// - "Play" abre fullscreen (o devuelve selección si venimos del player)
class EpgTimelinePage extends StatefulWidget {
  final List<Channel> channels;
  final String? playlistUrl;
  final bool returnSelection;

  /// Canal "activo" (para arrancar centrado en esa fila)
  final Channel? currentChannel;

  const EpgTimelinePage({
    super.key,
    required this.channels,
    this.playlistUrl,
    this.returnSelection = false,
    this.currentChannel,
  });

  @override
  State<EpgTimelinePage> createState() => _EpgTimelinePageState();
}

class _EpgTimelinePageState extends State<EpgTimelinePage> {
  static const double _leftColWidth = 290;
  static const double _rowH = 76;
  static const double _minuteW = 3.6; // 14h → ~3024px
  static const Duration _windowPast = Duration(hours: 2);
  static const Duration _windowFuture = Duration(hours: 12);

  final TextEditingController _search = TextEditingController();
  final ScrollController _vLeft = ScrollController();
  final ScrollController _vRight = ScrollController();
  final ScrollController _h = ScrollController();

  final Map<String, Future<List<EpgProgram>>> _winFutures = <String, Future<List<EpgProgram>>>{};

  bool _syncing = false;
  bool _loading = true;
  String? _error;

  List<String> _categories = const <String>['All'];
  String _selectedCategory = 'All';

  List<Channel> _visible = const <Channel>[];

  (DateTime, DateTime)? _rangeUtc;

  // Blindaje: en algunos entornos DateFormat puede lanzar LocaleDataException si no se inicializa
  // el símbolo de fechas del locale. Nos auto-curamos aquí para que el Módulo 3 nunca reviente.
  late final Future<void> _intlReady;

  @override
  void initState() {
    super.initState();

    _intlReady = _ensureIntlReady();

    _vLeft.addListener(() => _syncVertical(from: _vLeft, to: _vRight));
    _vRight.addListener(() => _syncVertical(from: _vRight, to: _vLeft));

    _rebuildCategories();
    _applyFilters();
    _bootstrap();
  }

  Future<void> _ensureIntlReady() async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final localeName = deviceLocale.toString(); // ej: es_ES
    final languageCode = deviceLocale.languageCode;

    // Alinea el default locale con el del dispositivo.
    intl.Intl.defaultLocale = localeName;

    // Inicialización best-effort: probamos locales habituales (incluyendo 'es' porque en la UI se usa explícito).
    for (final l in <String>[localeName, languageCode, 'es_ES', 'es', 'en_US']) {
      try {
        await initializeDateFormatting(l);
      } catch (_) {
        // ignore
      }
    }

    // Sanity: si aun así falla el formateo en el locale actual, caemos a en_US (no debe crashear).
    try {
      intl.DateFormat('EEE dd/MM', intl.Intl.getCurrentLocale()).format(DateTime.now());
    } catch (_) {
      intl.Intl.defaultLocale = 'en_US';
    }

    debugPrint('[VIVID][EPG] intl ready: ${intl.Intl.getCurrentLocale()}');
  }

  @override
  void dispose() {
    _search.dispose();
    _vLeft.dispose();
    _vRight.dispose();
    _h.dispose();
    super.dispose();
  }

  void _syncVertical({required ScrollController from, required ScrollController to}) {
    if (_syncing) return;
    if (!from.hasClients || !to.hasClients) return;
    if (!mounted) return;
    _syncing = true;
    final target = from.offset.clamp(to.position.minScrollExtent, to.position.maxScrollExtent);
    if ((to.offset - target).abs() > 0.5) {
      to.jumpTo(target);
    }
    _syncing = false;
  }

  void _rebuildCategories() {
    final set = <String>{};
    for (final c in widget.channels) {
      final g = (c.groupTitle ?? c.group ?? '').trim();
      if (g.isNotEmpty) set.add(g);
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _categories = <String>['All', ...list];
      if (!_categories.contains(_selectedCategory)) _selectedCategory = 'All';
    });
  }

  void _applyFilters() {
    final q = _search.text.trim().toLowerCase();
    final cat = _selectedCategory;
    final out = widget.channels.where((c) {
      final nameOk = q.isEmpty ? true : c.name.toLowerCase().contains(q);
      if (!nameOk) return false;
      if (cat == 'All') return true;
      final g = (c.groupTitle ?? c.group ?? '').trim();
      return g == cat;
    }).toList();

    // Limite suave para no morir en listas enormes.
    final limited = out.length > 180 ? out.sublist(0, 180) : out;

    setState(() {
      _visible = limited;
    });
  }

  Future<void> _bootstrap({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Asegura que intl está listo antes de que la UI empiece a formatear horas/fechas.
      await _intlReady;

      final epg = sl<EpgService>();
      await epg.ensureFresh(playlistUrl: widget.playlistUrl, force: force);
      final range = await epg.windowRangeUtc();
      setState(() {
        _rangeUtc = range;
      });

      // Scroll inicial hacia el canal actual (si existe en la lista filtrada).
      final current = widget.currentChannel;
      if (current != null) {
        final idx = _visible.indexWhere((c) => c.id == current.id);
        if (idx >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final offset = idx * _rowH;
            if (_vLeft.hasClients) _vLeft.jumpTo(offset.clamp(0, _vLeft.position.maxScrollExtent));
            if (_vRight.hasClients) _vRight.jumpTo(offset.clamp(0, _vRight.position.maxScrollExtent));
          });
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<EpgProgram>> _windowFor(Channel ch) {
    return _winFutures.putIfAbsent(ch.id, () => sl<EpgService>().lookupWindow(ch));
  }

  void _play(Channel ch) {
    if (widget.returnSelection) {
      context.pop(ch);
      return;
    }
    context.pushNamed(
      'player',
      extra: {
        'channel': ch,
        'channels': widget.channels,
        'playlistUrl': widget.playlistUrl,
        'quickOverlay': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeUtc = _rangeUtc;
    final nowUtc = DateTime.now().toUtc();

    // Fallback si no tenemos meta aún.
    final fallbackStart = nowUtc.subtract(_windowPast);
    final fallbackEnd = nowUtc.add(_windowFuture);
    final startUtc = (rangeUtc?.$1) ?? fallbackStart;
    final endUtc = (rangeUtc?.$2) ?? fallbackEnd;
    final totalMinutes = endUtc.difference(startUtc).inMinutes.clamp(1, 24 * 60);
    final timelineW = totalMinutes * _minuteW;
    final nowX = (nowUtc.difference(startUtc).inMinutes * _minuteW).clamp(0.0, timelineW);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.35,
                  colors: [Color(0xFF181818), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, startUtc, endUtc),
                _buildFilters(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: CinematicColors.accent))
                      : (_error != null)
                          ? _buildError()
                          : LayoutBuilder(
                              builder: (ctx, c) {
                                final contentH = c.maxHeight;
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: _leftColWidth,
                                      height: contentH,
                                      child: Column(
                                        children: [
                                          SizedBox(height: 44, child: _leftHeader()),
                                          Expanded(child: _buildChannelColumn()),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: _h,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: timelineW,
                                          height: contentH,
                                          child: Stack(
                                            children: [
                                              Column(
                                                children: [
                                                  SizedBox(height: 44, child: _buildTimelineHeader(startUtc, endUtc, timelineW)),
                                                  Expanded(child: _buildTimelineList(startUtc, endUtc)),
                                                ],
                                              ),
                                              Positioned(
                                                left: nowX,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 2,
                                                  color: CinematicColors.accent.withOpacity(0.85),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, DateTime startUtc, DateTime endUtc) {
    final fmt = intl.DateFormat('HH:mm');
    final left = fmt.format(startUtc.toLocal());
    final right = fmt.format(endUtc.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            splashRadius: 22,
          ),
          const SizedBox(width: 6),
          Text(
            'Guía • 14h',
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(width: 10),
          Text(
            '$left → $right',
            style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _bootstrap(force: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Actualizar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: CinematicColors.accent.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TextField(
                controller: _search,
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Buscar canal…',
                  hintStyle: GoogleFonts.montserrat(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w700),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 10),
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            initialValue: _selectedCategory,
            tooltip: 'Categorías',
            onSelected: (v) {
              setState(() => _selectedCategory = v);
              _applyFilters();
            },
            itemBuilder: (ctx) {
              return _categories
                  .map(
                    (c) => PopupMenuItem<String>(
                      value: c,
                      child: Text(c, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                    ),
                  )
                  .toList();
            },
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: CinematicColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CinematicColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCategory,
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 34),
            const SizedBox(height: 10),
            Text(
              'No se pudo cargar la guía',
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _bootstrap(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Reintentar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CinematicColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Text(
        'CANALES',
        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildChannelColumn() {
    return ListView.builder(
      controller: _vLeft,
      itemExtent: _rowH,
      itemCount: _visible.length,
      itemBuilder: (ctx, i) {
        final ch = _visible[i];
        return InkWell(
          onTap: () => _play(ch),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Row(
              children: [
                ChannelLogo(url: ch.logoUrl, width: 34, height: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_circle_fill_rounded, color: CinematicColors.accent.withOpacity(0.9), size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineHeader(DateTime startUtc, DateTime endUtc, double timelineW) {
    final start = startUtc.toLocal();
    final end = endUtc.toLocal();
    final totalMinutes = endUtc.difference(startUtc).inMinutes;
    final hours = (totalMinutes / 60.0).ceil();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(hours + 1, (i) {
                final t = start.add(Duration(hours: i));
                final x = (i * 60) * _minuteW;
                return SizedBox(
                  width: (i == hours) ? (timelineW - x) : (60 * _minuteW),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 12),
                    child: Text(
                      intl.DateFormat('HH:mm').format(t),
                      style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                );
              }),
            ),
          ),
          // divisores por hora
          Positioned.fill(
            child: CustomPaint(
              painter: _HourLinesPainter(totalMinutes: totalMinutes, minuteW: _minuteW),
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Text(
              '${intl.DateFormat('EEE dd/MM', intl.Intl.getCurrentLocale()).format(start)}',
              style: GoogleFonts.montserrat(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(DateTime startUtc, DateTime endUtc) {
    return ListView.builder(
      controller: _vRight,
      itemExtent: _rowH,
      itemCount: _visible.length,
      itemBuilder: (ctx, i) {
        final ch = _visible[i];
        return FutureBuilder<List<EpgProgram>>(
          future: _windowFor(ch),
          builder: (ctx, snap) {
            final programs = snap.data ?? const <EpgProgram>[];
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: _ProgramRow(
                channel: ch,
                startUtc: startUtc,
                endUtc: endUtc,
                minuteW: _minuteW,
                programs: programs,
                onPlay: () => _play(ch),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final Channel channel;
  final DateTime startUtc;
  final DateTime endUtc;
  final double minuteW;
  final List<EpgProgram> programs;
  final VoidCallback onPlay;

  const _ProgramRow({
    required this.channel,
    required this.startUtc,
    required this.endUtc,
    required this.minuteW,
    required this.programs,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final rangeMinutes = endUtc.difference(startUtc).inMinutes.clamp(1, 24 * 60);
    final totalW = rangeMinutes * minuteW;

    final blocks = <Widget>[];
    for (final p in programs) {
      final s = p.startUtc;
      final e = p.stopUtc;
      if (!e.isAfter(startUtc) || !s.isBefore(endUtc)) continue;

      final clampedStart = s.isBefore(startUtc) ? startUtc : s;
      final clampedEnd = e.isAfter(endUtc) ? endUtc : e;
      final leftMin = clampedStart.difference(startUtc).inMinutes;
      final durMin = clampedEnd.difference(clampedStart).inMinutes.clamp(1, 24 * 60);

      final left = leftMin * minuteW;
      final w = durMin * minuteW;
      blocks.add(Positioned(
        left: left,
        top: 10,
        bottom: 10,
        width: w,
        child: _ProgramBlock(program: p),
      ));
    }

    return InkWell(
      onTap: onPlay,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridLinesPainter(totalMinutes: rangeMinutes, minuteW: minuteW),
            ),
          ),
          Positioned.fill(
            child: SizedBox(
              width: totalW,
              child: Stack(children: blocks),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white70.withOpacity(0.8), size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramBlock extends StatelessWidget {
  final EpgProgram program;
  const _ProgramBlock({required this.program});

  @override
  Widget build(BuildContext context) {
    final start = program.startUtc.toLocal();
    final stop = program.stopUtc.toLocal();
    final time = '${intl.DateFormat('HH:mm').format(start)}–${intl.DateFormat('HH:mm').format(stop)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HourLinesPainter extends CustomPainter {
  final int totalMinutes;
  final double minuteW;

  const _HourLinesPainter({required this.totalMinutes, required this.minuteW});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final hours = (totalMinutes / 60.0).ceil();
    for (int i = 0; i <= hours; i++) {
      final x = (i * 60) * minuteW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HourLinesPainter oldDelegate) {
    return oldDelegate.totalMinutes != totalMinutes || oldDelegate.minuteW != minuteW;
  }
}

class _GridLinesPainter extends CustomPainter {
  final int totalMinutes;
  final double minuteW;

  const _GridLinesPainter({required this.totalMinutes, required this.minuteW});

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1;

    final hours = (totalMinutes / 60.0).ceil();
    for (int i = 0; i <= hours; i++) {
      final x = (i * 60) * minuteW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), hourPaint);

      if (i < hours) {
        final hx = x + (30 * minuteW);
        canvas.drawLine(Offset(hx, 0), Offset(hx, size.height), halfPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) {
    return oldDelegate.totalMinutes != totalMinutes || oldDelegate.minuteW != minuteW;
  }
}
