import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnistream_iptv/injection_container.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/epg/epg_country_catalog.dart';
import 'package:omnistream_iptv/core/epg/epg_service.dart';
import 'package:omnistream_iptv/core/epg/epg_settings_store.dart';
import 'package:omnistream_iptv/core/storage/recent_playback_store.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';

class EpgSettingsPage extends StatefulWidget {
  const EpgSettingsPage({super.key});

  @override
  State<EpgSettingsPage> createState() => _EpgSettingsPageState();
}

class _EpgSettingsPageState extends State<EpgSettingsPage> {
  late EpgSettings _settings;
  final TextEditingController _overrideCtrl = TextEditingController();
  bool _saving = false;
  bool _refreshing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _settings = sl<EpgSettingsStore>().load();
    _overrideCtrl.text = (_settings.overrideUrl ?? '').trim();
  }

  @override
  void dispose() {
    _overrideCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
    });

    try {
      final s = _settings.copyWith(overrideUrl: _overrideCtrl.text.trim());
      await sl<EpgSettingsStore>().save(s);
      setState(() {
        _settings = s;
        _status = 'Guardado';
      });
    } catch (e) {
      setState(() => _status = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _lastPlaylistUrl() async {
    final last = await sl<RecentPlaybackStore>().loadLastChannel();
    final p = (last?.playlistUrl ?? '').trim();
    return p.isEmpty ? null : p;
  }

  Future<void> _refreshNow({String? playlistUrl}) async {
    setState(() {
      _refreshing = true;
      _status = 'Actualizando EPG…';
    });
    try {
      await sl<EpgService>().ensureFresh(playlistUrl: playlistUrl, force: true);
      setState(() => _status = 'EPG actualizado ✅');
    } catch (e) {
      setState(() => _status = 'No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget _chip({required String label, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? CinematicColors.accent : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? Colors.transparent : Colors.white.withOpacity(0.10)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: CinematicColors.accent.withOpacity(0.22),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22);
    final hintStyle = GoogleFonts.montserrat(color: Colors.white60, height: 1.4);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('EPG', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.6,
                  colors: [Color(0xFF161616), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text('Guía EPG (NOW / NEXT)', style: titleStyle),
                const SizedBox(height: 8),
                Text(
                  'AUTO intenta derivar XMLTV desde una lista Xtream. Si no es posible (o falla la descarga), se usa el fallback por país.',
                  style: hintStyle,
                ),
                const SizedBox(height: 18),

                // Mode selector
                _glassSection(
                  title: 'Modo',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip(
                        label: 'AUTO',
                        active: _settings.mode == EpgMode.auto,
                        onTap: () => setState(() => _settings = _settings.copyWith(mode: EpgMode.auto)),
                      ),
                      _chip(
                        label: 'OVERRIDE URL',
                        active: _settings.mode == EpgMode.override,
                        onTap: () => setState(() => _settings = _settings.copyWith(mode: EpgMode.override)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Override URL
                _glassSection(
                  title: 'URL Override (opcional)',
                  subtitle: 'Se usa si el modo es OVERRIDE. Acepta .xml o .xml.gz',
                  child: TextField(
                    controller: _overrideCtrl,
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'https://…/epg.xml.gz',
                      hintStyle: GoogleFonts.montserrat(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: CinematicColors.accent.withOpacity(0.65), width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Fallback country + gzip preference
                _glassSection(
                  title: 'Fallback por país',
                  subtitle: 'Si AUTO no deriva o falla, usa iptv-epg.org por país (por defecto ES).',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _countryDropdown(),
                          _togglePreferGzip(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _refreshHoursSlider(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Effective URL info + meta
                FutureBuilder<String?>(
                  future: _lastPlaylistUrl(),
                  builder: (context, snap) {
                    final playlistUrl = snap.data;
                    final effective = sl<EpgService>().resolveEffectiveUrl(playlistUrl: playlistUrl);

                    return _glassSection(
                      title: 'URL efectiva',
                      subtitle: playlistUrl == null
                          ? 'No hay playlist reciente detectada (se mostrará el fallback actual).'
                          : 'Detectada playlist reciente → se calcula AUTO/override con esa URL.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            effective.toString(),
                            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _refreshing ? null : () => _refreshNow(playlistUrl: playlistUrl),
                                  icon: _refreshing
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.refresh_rounded),
                                  label: Text(
                                    _refreshing ? 'Actualizando…' : 'Actualizar ahora',
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w900),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CinematicColors.accent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _saving ? null : _save,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: CinematicColors.accent.withOpacity(0.55)),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(_saving ? 'Guardando…' : 'Guardar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_status != null)
                            Text(_status!, style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          FutureBuilder<(Uri, Map<String, dynamic>)>(
                            future: sl<EpgService>().info(playlistUrl: playlistUrl),
                            builder: (context, infoSnap) {
                              final meta = infoSnap.data?.$2 ?? {};
                              final fetched = (meta['fetchedAt'] ?? '').toString();
                              final chCount = (meta['channelCount'] ?? '').toString();
                              final prCount = (meta['programCount'] ?? '').toString();
                              final src = (meta['sourceUrl'] ?? '').toString();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Última carga', style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(fetched.isEmpty ? '—' : fetched, style: GoogleFonts.montserrat(color: Colors.white70)),
                                  const SizedBox(height: 10),
                                  Text('Contenido', style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(
                                    (chCount.isEmpty && prCount.isEmpty) ? '—' : 'Canales: $chCount  •  Programas: $prCount',
                                    style: GoogleFonts.montserrat(color: Colors.white70),
                                  ),
                                  if (src.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text('Fuente cacheada', style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    SelectableText(src, style: GoogleFonts.montserrat(color: Colors.white70)),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection({required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: GoogleFonts.montserrat(color: Colors.white54, height: 1.35, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _countryDropdown() {
    final items = EpgCountryCatalog.countries.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _settings.fallbackCountry,
          dropdownColor: const Color(0xFF161616),
          iconEnabledColor: Colors.white70,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e.code,
                  child: Text('${e.name} (${e.code})', style: GoogleFonts.montserrat(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings = _settings.copyWith(fallbackCountry: v));
          },
        ),
      ),
    );
  }

  Widget _togglePreferGzip() {
    return InkWell(
      onTap: () => setState(() => _settings = _settings.copyWith(preferGzip: !_settings.preferGzip)),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_settings.preferGzip ? Icons.archive_rounded : Icons.description_outlined, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              _settings.preferGzip ? 'Preferir .gz' : 'Preferir .xml',
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refreshHoursSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frecuencia de refresco', style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: 1,
                max: 24,
                divisions: 23,
                value: _settings.refreshHours.toDouble().clamp(1, 24),
                onChanged: (v) => setState(() => _settings = _settings.copyWith(refreshHours: v.round())),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                '${_settings.refreshHours}h',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
