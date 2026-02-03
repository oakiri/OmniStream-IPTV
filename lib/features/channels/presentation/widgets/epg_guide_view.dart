import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/epg/epg_service.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/channel.dart';
import 'package:omnistream_iptv/features/channels/presentation/widgets/channel_logo.dart';

class EpgGuideView extends StatefulWidget {
  final List<Channel> channels;
  final Channel currentChannel;
  final String? playlistUrl;
  final ValueChanged<Channel> onChannelSelected;

  const EpgGuideView({
    super.key,
    required this.channels,
    required this.currentChannel,
    required this.onChannelSelected,
    this.playlistUrl,
  });

  @override
  State<EpgGuideView> createState() => _EpgGuideViewState();
}

class _EpgGuideViewState extends State<EpgGuideView> {
  bool _loading = true;
  bool _refreshing = false;
  String _query = '';
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
    });

    try {
      await sl<EpgService>().ensureFresh(playlistUrl: widget.playlistUrl, force: force);
    } catch (_) {
      // Silent - the UI will show "Sin EPG" per channel if not available.
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
      });

      // Scroll to current channel on first load.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final idx = widget.channels.indexWhere((c) => c.id == widget.currentChannel.id);
        if (idx >= 0) {
          _scrollCtrl.jumpTo((idx * 86).toDouble().clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      });
    }
  }

  List<Channel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.channels;
    return widget.channels
        .where((c) => c.name.toLowerCase().contains(q) || (c.groupTitle ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 820;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [Color(0xFF181818), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isWide),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: CinematicColors.accent))
                    : _buildList(isWide),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    final time = DateFormat('HH:mm').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CinematicColors.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CinematicColors.accent.withOpacity(0.30)),
                ),
                child: const Icon(Icons.view_timeline_rounded, color: CinematicColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guía rápida', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('NOW / NEXT • $time', style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar EPG',
                onPressed: _refreshing
                    ? null
                    : () {
                        setState(() => _refreshing = true);
                        _load(force: true);
                      },
                icon: _refreshing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, color: Colors.white70),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar canal…',
                hintStyle: GoogleFonts.montserrat(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isWide) {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(child: Text('Sin resultados', style: GoogleFonts.montserrat(color: Colors.white30)));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final ch = list[i];
        final isCurrent = ch.id == widget.currentChannel.id;

        final nowNext = sl<EpgService>().lookupNowNext(ch);

        return _EpgRow(
          channel: ch,
          nowNext: nowNext,
          isCurrent: isCurrent,
          onTap: () => widget.onChannelSelected(ch),
        );
      },
    );
  }
}

class _EpgRow extends StatelessWidget {
  final Channel channel;
  final EpgNowNext? nowNext;
  final bool isCurrent;
  final VoidCallback onTap;

  const _EpgRow({
    required this.channel,
    required this.nowNext,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nowUtc = DateTime.now().toUtc();

    final now = nowNext?.now;
    final next = nowNext?.next;

    double? progress;
    if (now != null && nowUtc.isAfter(now.start) && nowUtc.isBefore(now.stop)) {
      final total = now.stop.difference(now.start).inSeconds;
      if (total > 0) {
        final done = nowUtc.difference(now.start).inSeconds;
        progress = (done / total).clamp(0.0, 1.0);
      }
    }

    final nowTime = (now == null) ? '' : '${DateFormat('HH:mm').format(now.start.toLocal())}–${DateFormat('HH:mm').format(now.stop.toLocal())}';
    final nextTime = (next == null) ? '' : '${DateFormat('HH:mm').format(next.start.toLocal())}–${DateFormat('HH:mm').format(next.stop.toLocal())}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent ? CinematicColors.accent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCurrent ? CinematicColors.accent.withOpacity(0.35) : Colors.white.withOpacity(0.06),
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: CinematicColors.accent.withOpacity(0.16),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            ChannelLogo(url: channel.logoUrl, width: 42, height: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),

                  // NOW
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.10)),
                        ),
                        child: Text('NOW', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          now?.title ?? 'Sin EPG',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (nowTime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(nowTime, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation(CinematicColors.accent),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // NEXT
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.10)),
                        ),
                        child: Text('NEXT', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          next?.title ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (nextTime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(nextTime, style: GoogleFonts.montserrat(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.play_circle_fill_rounded, color: isCurrent ? CinematicColors.accent : Colors.white30),
          ],
        ),
      ),
    );
  }
}
