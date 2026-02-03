import 'dart:ui' show PlatformDispatcher;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnistream_iptv/core/epg/epg_models.dart';
import 'package:omnistream_iptv/core/epg/epg_country_catalog.dart';

class EpgSettingsStore {
  static const _kMode = 'epg.mode';
  static const _kOverrideUrl = 'epg.override_url';
  static const _kFallbackCountry = 'epg.fallback_country';
  static const _kRefreshHours = 'epg.refresh_hours';
  static const _kPreferGzip = 'epg.prefer_gzip';

  final SharedPreferences prefs;

  EpgSettingsStore({required this.prefs});

  EpgSettings load() {
    final rawMode = (prefs.getString(_kMode) ?? 'auto').toLowerCase();
    final mode = rawMode == 'override' ? EpgMode.override : EpgMode.auto;

    final overrideUrl = prefs.getString(_kOverrideUrl);

    final localeCc = PlatformDispatcher.instance.locale.countryCode;
    final fallback = EpgCountryCatalog.normalizeFallback(
      prefs.getString(_kFallbackCountry) ?? localeCc,
    );

    final refreshHours = prefs.getInt(_kRefreshHours) ?? 6;
    final preferGzip = prefs.getBool(_kPreferGzip) ?? true;

    return EpgSettings(
      mode: mode,
      overrideUrl: overrideUrl,
      fallbackCountry: fallback,
      refreshHours: refreshHours.clamp(1, 72),
      preferGzip: preferGzip,
    );
  }

  Future<void> save(EpgSettings s) async {
    await prefs.setString(_kMode, s.mode.name);
    if ((s.overrideUrl ?? '').trim().isEmpty) {
      await prefs.remove(_kOverrideUrl);
    } else {
      await prefs.setString(_kOverrideUrl, s.overrideUrl!.trim());
    }
    await prefs.setString(_kFallbackCountry, EpgCountryCatalog.normalizeFallback(s.fallbackCountry));
    await prefs.setInt(_kRefreshHours, s.refreshHours.clamp(1, 72));
    await prefs.setBool(_kPreferGzip, s.preferGzip);
  }
}
